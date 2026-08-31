local function getvideo(
	lanes,
	args,
	aspect,
	audio_command,
	get_vmaf,
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
	local txt = "av1_scenes.txt"
	local path = pl.path
	local stringx = pl.stringx
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
		if total_frames ~= "error" then
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
	local no_vmaf_command
	local workers = args.workers
	local noise = args.noise
	--set values according to certain factors
	if not workers then
		workers = 0
	end
	local function txt_decode(txt_file)
		local txt_table = {}
		local previous_time
		for line in io.lines(txt_file) do
			local time = line:match("pts:(%d+)")
			if time then
				if not previous_time then
					previous_time = 0
				end
				table.insert(txt_table, { tonumber(previous_time), tonumber(time) })
				previous_time = time
			end
		end
		if not previous_time then
			local time = total_frames + 1
			previous_time = 0
			table.insert(txt_table, { tonumber(previous_time), tonumber(time) })
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
			if workers > 1 then
			else
				local scenes = get_scenes()
				video_quality = get_vmaf(
					input,
					ffprobe,
					gpu,
					args,
					output,
					video_command,
					get_quality,
					pl,
					base,
					ffv1_command,
					filters,
					scenes,
					false
				)
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
			base(filters.ffmpeg, input),
			video_command,
			audio_command,
			utils.quote_arg(output)
		)
	end
	return video_command
end
return getvideo
