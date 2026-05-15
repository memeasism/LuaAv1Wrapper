local function getvideo(
	args,
	aspect,
	audio_command,
	cjson,
	content,
	ffprobe,
	input,
	filters,
	fps_table,
	get_quality,
	gpu,
	no_subtitle_extensions,
	output,
	pl
)
	--define static variables
	local path = pl.path
	local temporary = output .. "_temp.mkv"
	local json = "av1_scenes.json"
	local output_format = path.extension(output)
	local reference = temporary .. "_ref.mkv"
	local skip_vmaf = args.skipvmaf
	local utils = pl.utils
	local video_codec = args.video
	--define variables that are mutable
	local vmaf
	local fps_number = tonumber(fps_table.fpsdividendtxt) / tonumber(fps_table.fpsdivisortxt)
	local video_quality = args.videoquality
	local skip_subtitles
	local video_command
	local remux_command
	local no_vmaf_command
	local workers = args.workers
	local noise = args.noise
	--set values according to certain factors
	if not workers then
		workers = 0
	end
	local function vmaf_range(start, stop)
		local result = {}
		for v = start, stop, -1 do
			table.insert(result, v)
		end
		return result
	end
	vmaf = vmaf_range(
		97 --[[(Start)From my understanding the optimal "visually lossless" VMAF score]],
		80 --[[(Stop) just picked a low vmaf number]]
	)
	for key, value in pairs(no_subtitle_extensions) do
		if string.match(output_format, value) then
			skip_subtitles = "-sn"
		end
	end
	if not skip_subtitles then
		skip_subtitles = ""
	end
	if string.find(content, "Telecined") or string.find(content, "Mixed") then
		fps_number = fps_number * 0.8
	end
	if string.find(content, "Interlaced") then
		fps_number = fps_number * 2
	end
	if not video_codec then
		video_codec = "av1"
	end --checks if user set the video argument
	if not noise then
		noise = 0
	end --sets noise to be what the user set
	if args.video_quality then
		video_quality = args.videoquality
	end
	--define the command functions
	local function base(vspipe, file)
		local command = string.format(
			[[%s ffmpeg -i "%s" -f yuv4mpegpipe -i pipe: -filter_complex "[1:v:0]setdar=%s" -map 1:v:0 -map 0:a? -map 0:s? -c:s copy %s -fflags +genpts -async 0]],
			vspipe,
			file,
			aspect,
			skip_subtitles
		)
		return command
	end
	local ffv1_command = [[-c:v ffv1 -context 1 -g 1 -level 3 -slices 30 -coder 1 -pix_fmt yuv420p10le]]
	local function remux(file)
		local command
		command = string.format(
			[[ffmpeg -i "%s" -i "%s" -map 0:v:0 -map 1:a? -map 1:s? -c:v copy -aspect %s -c:s copy -fflags +genpts -async 0  %s %s "%s"]],
			file,
			input,
			string.gsub(aspect, "/", ":"),
			audio_command,
			skip_subtitles,
			output
		)
		return command
	end
	local function cpu_command(out, target_vmaf, quality)
		local command
		command = string.format(
			[[av1an -i %s --proxy %s -o "%s" --workers %s -e "aom" --pix-format yuv420p10le --scenes %s --target-metric vmaf --target-quality %s -v "--denoise-noise-level=%s"]],
			filters.av1an,
			filters.proxy.av1an,
			out,
			workers,
			json,
			target_vmaf,
			noise
		)
		if quality then
			command = string.format(
				[[av1an -i %s --proxy %s -o "%s" --workers %s -e "aom" --pix-format yuv420p10le --scenes %s --target-metric vmaf --target-quality %s -v "--cq-level=%s --denoise-noise-level=%s"]],
				filters.av1an,
				filters.proxy.av1an,
				out,
				workers,
				json,
				vmaf,
				quality,
				noise
			)
		end
		return command
	end
	local function intel_cmd(quality)
		local string = string.format(
			[[-c:v av1_qsv -qscale:v %s -preset veryslow -extbrc 1 -look_ahead 1 -look_ahead_depth 60 -look_ahead_downsampling off -refs 16 -adaptive_i 1 -adaptive_b 1 -low_power 0 -pix_fmt p010le -vtag av01]],
			quality
		)
		return string
	end
	local function find_vmaf()
		pl.file.delete(json) --delete leftovers from a possibly failed encode
		--set static variables
		local av1an_split_command = string.format([[av1an -i %s --sc-only -s %s]], filters.proxy.av1an, json)
		--set mutable variables
		local current_vmaf = 0
		local current_command
		local scene_frames = {}
		local vmaf_to_cq = {}
		local count = 0
		local cq = 50
		local oldcq = 50
		local divisor
		--start function
		print("Using Av1an to detect scenes so we can test quality on multiple scenes!")
		utils.execute(av1an_split_command)
		local scenes = pl.file.read(json) --read the output of av1an scene detection
		if not scenes then
			--if the scenes file doesn't exist then error
			print("Unable to read the scene json file")
			utils.quit()
		end
		scenes = cjson.decode(scenes)
		if not scenes then
			print("Unable to decode the scenes json file")
			utils.quit()
		end
		if #scenes.scenes >= 4 then
			divisor = 4
			while count < 4 do
				local random = math.random(1, #scenes.scenes)
				if not scene_frames[random] then
					scene_frames[random] = scenes.scenes[random]
					count = count + 1
				end
			end
		else --both of these if statements just add random scenes to a table, 4 by default but in rare instances if there are less than 4 it just does them all
			divisor = #scenes.scenes
			while count < #scenes.scenes do
				local random = math.random(1, #scenes.scenes)
				if not scene_frames[random] then
					scene_frames[random] = scenes.scenes[random]
					count = count + 1
				end
			end
		end

		for key, value in pairs(scene_frames) do
			pl.file.delete(reference) --delete previous reference/reference reference from failed encode
			cq = oldcq --set cq back to 50 or a safe starting point for a new scene
			local vmaf_values = {}
			local scene_success
			local start_time = value.start_frame / fps_number
			local stop_time = (value.end_frame - value.start_frame + 1) / fps_number
			local vmaf_command = string.format(
				[[ffmpeg -i "%s" -i "%s" -filter_complex "[0:v:0]scale=1920:1080[distorted];[1:v:0]scale=1920:1080[reference];[distorted][reference]libvmaf" -f null -]],
				temporary,
				reference
			)
			local reference_command = string.format(
				[[%s -ss %f -t %f -c:a copy %s "%s"]],
				base(filters.proxy.ffmpeg, input),
				start_time,
				stop_time,
				ffv1_command,
				reference
			)
			count = 0
			local reference_success
			while not reference_success and count < 5 do
				print(
					"Encoding reference! This part can be fast or take a while, no matter what, it speeds up the process overall."
				)
				pl.file.delete(reference)
				reference_success = utils.executeex(reference_command)
				count = count + 1
			end
			for key, target_vmaf in pairs(vmaf) do
				if not vmaf_values[1] then --checks if the vmaf_values table exists, this table is so we can encode less saving the user time and money!
					while current_vmaf < target_vmaf and cq > 2 do
						cq = cq - 2
						pl.file.delete(temporary) --delete old temp file
						local command = video_command(cq)
						local temporary_command = string.format(
							[[ffmpeg -i "%s" -map 0:v:0 -map 0:a? -map 0:s? -c:s copy -c:a copy -fflags +genpts -async 0 %s "%s"]],
							reference,
							command,
							temporary
						)
						local command_success = utils.executeex(temporary_command)
						if not command_success then
							print("encoding to av1 failed!")
						end
						local success, returncode, command_out, errout = utils.executeex(vmaf_command) --not sure why but ffmpeg puts this stuff in the err out at least on windows
						if success then
							local vmaf_string = string.match(errout, "VMAF score:%s*([%d.]+)")
							local vmaf_score = tonumber(vmaf_string)
							if vmaf_score then
								current_vmaf = vmaf_score
								vmaf_values[#vmaf_values + 1] = { vmaf_score, cq }
							end
						end
					end
				end
				for key, vmaf_value in pairs(vmaf_values) do
					if vmaf_value[1] >= target_vmaf then
						--this is such simple code that saves so much time and money, idk why but I just felt this should be pointed out, maybe because some people might not think of it
						current_vmaf = vmaf_value[1]
						cq = vmaf_value[2]
						break
					end
				end
				if current_vmaf >= target_vmaf then
					scene_success = true
					vmaf_to_cq[#vmaf_to_cq + 1] = cq
					cq = cq + 10 --add 8 but also 2 more due to how the loop works, this way we waste less time narrowing the vmaf in theory
					if cq > 50 then
						cq = 50
					end
					oldcq = cq
					current_vmaf = 0
					--if vmaf is set successfully then break the loop and set current vmaf to a better starting position to reach the vmaf faster
					break
				else
					cq = oldcq
				end
			end
			if not scene_success then --checks if a scene failed to encode and breaks
				break
			end
		end
		--delete temp files
		pl.file.delete(temporary)
		pl.file.delete(reference)
		pl.file.delete(json)
		--make sure that there are enough cq values to parse
		if #vmaf_to_cq < divisor then
			--if there's not enough cq values, it does a fallback
			print("failed to get the vmaf score, requesting from module or using fallback")
			if args.fallbackquality then
				video_quality = args.fallbackquality
			else
				video_quality = get_quality(input, ffprobe, gpu, args, pl)
			end
			return video_quality
		end
		local previous
		for key, value in pairs(vmaf_to_cq) do
			if previous then
				previous = previous + value
			else --simple code to add the values
				previous = value
			end
		end
		video_quality = previous / divisor --divide the added values by the divisor to get the mean(average) quality
		return video_quality
	end
	--these set the commands for encoding
	if video_codec == "av1" then
		if gpu == 0 then
			pl.file.delete(json)
			remux_command = remux(temporary)
			video_quality = get_quality(input, ffprobe, gpu, args, pl)
			no_vmaf_command = cpu_command(temporary, nil, video_quality)
			if not pl.file.read(temporary) then
				for key, value in pairs(vmaf) do
					video_command = cpu_command(temporary, value)
					if args.video_quality or skip_vmaf then
						print(no_vmaf_command)
						utils.execute(no_vmaf_command)
					else
						print(video_command)
						utils.execute(video_command)
					end
					if not pl.file.read(temporary) then
						print("Intermediary file not found! Running fallback command")
					else
						break
					end
				end
				if not pl.file.read(temporary) then
					print("All fallback commands failed, resorting to no vmaf")
					video_quality = get_quality(input, ffprobe, gpu, args, pl)
					utils.execute(no_vmaf_command)
				end
			else
				print("temporary file already exists, attempting to remux")
			end
			print("Encoding audio and copying subtitles to the output file")
			print(remux_command)
			utils.execute(remux_command)
			if not pl.file.read(output) then
				print("Video failed to be remuxed")
				utils.quit()
			end
			print("Remux success! Removing the intermediary video file")
			pl.file.delete(temporary)
			pl.file.delete(json)
			video_command = "skip"
			skip_vmaf = true
		else
			if gpu == 1 then
				video_command = intel_cmd
			end
			--[[if gpu == 2 then
			video_command = amdcmd
		end
		if gpu == 3 then
			video_command = nvidiacmd
		end]]
			if not (video_quality or skip_vmaf) then
				video_quality = find_vmaf()
			else
				video_quality = get_quality(input, ffprobe, gpu, args, pl)
			end
			video_command = video_command(video_quality)
		end
	end
	if video_codec == "ffv1" then
		video_command = ffv1_command
	end --sets and runs encoding commands
	if not video_command then
		print("Failed to get video command")
		utils.quit()
	end
	if video_command ~= "skip" then
		video_command = string.format(
			"%s %s %s %s",
			base(filters.ffmpeg, input),
			video_command,
			audio_command,
			utils.quote_arg(output)
		)
	end
	return video_command
end
return getvideo
