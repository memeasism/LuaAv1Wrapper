local function getvideo(
	lanes,
	args,
	aspect,
	audio_command,
	get_vmaf,
	parallel_encoding,
	cjson,
	content,
	count_frames,
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
	local test_scene_count = 8
	local txt = "av1_scenes.txt"
	local cat_txt = "cat.txt"
	local path = pl.path
	local output_format = path.extension(output)
	local skip_vmaf = args.skipvmaf
	local utils = pl.utils
	local video_codec = args.video
	--define variables that are mutable
	local fps_number = tonumber(fps_table.fpsdividendtxt) / tonumber(fps_table.fpsdivisortxt)
	local total_frames
	local nb_frames = ffprobe.video.streams[1].nb_frames
	local fallback_frames = ffprobe.video.format.duration
	local keyframe_interval = math.floor(fps_number * 10)
	if nb_frames then
		total_frames = tonumber(nb_frames) - 1
	else
		print("Could not get frame count from ffprobe, counting frames!")
		total_frames = count_frames(input, pl)
		if total_frames then
			total_frames = total_frames - 1
		else
			print("Counting frames failed, time to guess!")
			total_frames = math.floor(((tonumber(fallback_frames) * fps_number) + 0.5)) - 5 --I had issues with subtracting smaller numbers, 5 seems to be safe
		end
	end
	if (not total_frames) or (total_frames == "error") then
		print("Error getting file duration, skipping!")
		return "skip"
	end
	local video_quality = args.videoquality
	local skip_subtitles
	local video_command
	local remux_command
	local merge_command
	local workers = args.workers or 1
	local vmaf_workers = args.vworkers or 2
	local noise = args.noise
	--set values according to certain factors
	local function split_table(tbl, amount)
		local result = {}
		for i = 1, amount do
			result[i] = {}
		end
		local index = 1
		for _, v in ipairs(tbl) do
			table.insert(result[index], v)
			index = (index % amount) + 1
		end
		return result
	end
	local function txt_decode(txt_file)
		local txt_table = {}
		local previous_time = 0
		for line in io.lines(txt_file) do
			print(line)
			local time = line:match("pts:(%d+)")
			local scene = line:match("frame:(%d+)")
			if time and scene then
				table.insert(txt_table, { tonumber(previous_time), tonumber(time), tonumber(scene) + 1 })
				previous_time = time
			end
		end

		local time = total_frames + 1
		if previous_time == 0 then
			table.insert(txt_table, { tonumber(previous_time), tonumber(time), 1 })
		else
			table.insert(txt_table, { tonumber(previous_time), tonumber(time), txt_table[#txt_table][3] + 1 })
		end
		return txt_table
	end

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
			[[ffmpeg -f concat -safe 0 -i "%s" -i "%s" -map 0:v:0 -map 1:a? -map 1:s? -c:v copy -aspect %s -c:s copy -fflags +genpts -async 0  %s %s "%s"]],
			cat_txt,
			file,
			string.gsub(aspect, "/", ":"),
			audio_command,
			skip_subtitles,
			output
		)
		return command
	end
	local function cpu_command(quality)
		local command
		command = string.format(
			[[-c:v libsvtav1 -crf %s -preset 4 -g %s -level 5.1 -tier high -pix_fmt yuv420p10le -vtag av01 -svtav1-params "tune=0:enable-qm=1:scd=1:lookahead=120:film-grain=%s:film-grain-denoise=1:enable-overlays=1"]],
			quality,
			keyframe_interval,
			noise
		)
		return command
	end
	local function intel_cmd(quality)
		local string = string.format(
			[[-c:v av1_qsv -global_quality %s -preset veryslow -g %s -extbrc 1 -look_ahead 1 -look_ahead_depth 60 -look_ahead_downsampling off -refs 16 -adaptive_i 1 -adaptive_b 1 -low_power 0 -pix_fmt p010le -vtag av01]],
			quality,
			keyframe_interval
		)
		return string
	end
	local function get_scenes()
		pl.file.delete(txt) --delete leftovers from a possibly failed encode
		local vmaf_split_command = string.format(
			[[%s ffmpeg -i pipe: -filter:v "settb=1/%s,select='gt(scene,0.3)',metadata=print:file=%s" -f null -]],
			string.format(filters.proxy.ffmpeg, 0, total_frames),
			fps_number,
			txt
		)
		print("Using ffmpeg to detect scenes so we can test quality on multiple scenes!")
		utils.execute(vmaf_split_command)
		local scenes = pl.file.read(txt) --read the output of ffmpeg scene detection
		if not scenes then
			--if the scenes file doesn't exist then error
			print("Unable to read the scene txt file")
			utils.quit()
		end
		scenes = txt_decode(txt)
		if not scenes then
			print("Unable to decode the scenes txt file")
			return "error"
		end
		return scenes
	end
	--these set the commands for encoding
	if video_codec == "av1" then
		if gpu == 0 then
			video_command = cpu_command
		end
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
			local parallel = lanes.gen("*", parallel_encoding)
			local threads = {}
			local results = {}
			if workers > 1 then
				local current_worker = 0
				local scenes = get_scenes()
				scenes = split_table(scenes, workers)
				for i, v in ipairs(scenes) do
					current_worker = current_worker + 1
					table.insert(
						threads,
						parallel(
							input,
							ffprobe,
							gpu,
							args,
							output,
							video_command,
							get_quality,
							base,
							ffv1_command,
							filters,
							v,
							true,
							false,
							get_vmaf
						)
					)
				end
				for i, v in ipairs(threads) do
					local result = v
					for _, r in ipairs(result) do
						for _, out in ipairs(r) do
							table.insert(results, out)
						end
					end
				end
				local function alphanumsort(o)
					local function padnum(d)
						return ("%03d%s"):format(#d, d)
					end
					table.sort(o, function(a, b)
						return tostring(a):gsub([[_(%d+).mkv."$]], padnum) < tostring(b):gsub([[_(%d+).mkv."$]], padnum)
					end)
					return o
				end
				if #results > 1 then
					results = alphanumsort(results)
				end
				pl.pretty(results)
				for i, v in ipairs(results) do
					pl.file.delete(cat_txt)
					utils.execute(string.format([[echo file %s >> %s]], v:gsub("\\", "/"), cat_txt))
				end
				local command = remux(input)
				print(command)
				utils.execute(command)
				pl.file.delete(cat_txt)
				utils.quit()
			else
				local scenes = get_scenes()
				local divisor
				local scene_frames = {}
				local count = 0
				if #scenes >= test_scene_count then
					divisor = test_scene_count
					while count < test_scene_count do
						local random = math.random(1, #scenes)
						if not scene_frames[random] then
							scene_frames[random] = scenes[random]
							count = count + 1
						end
					end
				else --both of these if statements just add random scenes to a table, 4 by default but in rare instances if there are less than 4 it just does them all
					divisor = #scenes
					while count < #scenes do
						local random = math.random(1, #scenes)
						if not scene_frames[random] then
							scene_frames[random] = scenes[random]
							count = count + 1
						end
					end
				end
				scenes = split_table(scenes, vmaf_workers)
				for i, v in ipairs(scenes) do
					table.insert(
						threads,
						parallel(
							input,
							ffprobe,
							gpu,
							args,
							output,
							video_command,
							get_quality,
							base,
							ffv1_command,
							filters,
							v,
							false,
							false,
							get_vmaf
						)
					)
				end
				for i, v in ipairs(threads) do
					local result = v
					for _, r in ipairs(result) do
						for _, quality in ipairs(r) do
							table.insert(results, quality)
						end
					end
				end
				local previous
				for i, v in pairs(results) do
					if previous then
						previous = previous + v
					else --simple code to add the values
						previous = v
					end
				end
				video_quality = previous / #threads
			end
		else
			video_quality = get_quality(input, ffprobe, gpu, args, pl)
		end
		video_command = video_command(video_quality)
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
			base(string.format(filters.ffmpeg, 0, total_frames), input),
			video_command,
			audio_command,
			utils.quote_arg(output)
		)
	end
	return video_command
end
return getvideo
