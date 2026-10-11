local function parallel_encoding(
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
	scenes,
	parallel,
	quality,
	get_vmaf,
	fps_number,
	total_frames,
	temp_folder,
	resume
)
	math.randomseed(os.time())
	local length = math.floor((fps_number * 10) + 0.5) --find vmaf bases upon 10 second segments of a scene, this works pretty great since scene have to be uniform enough throughout to not be detected as a new one.
	local output_table = {}
	local previous_cq
	local pl = require("pl.import_into")()
	local utils = pl.utils
	local command_base
	output = pl.path.join(temp_folder, pl.path.basename(output))

	for i, v in ipairs(scenes) do
		local vmaf_previous_time = v[1]
		local vmaf_time = v[2]
		local vmaf_scene = v[3]
		local pre_roll = math.min(v[1], length)
		local vmaf_pre_roll = pre_roll
		local vspipe_start = v[1] - pre_roll
		if quality == false then
			if vmaf_time - vmaf_previous_time > length then
				vmaf_previous_time = math.random(vmaf_previous_time, (vmaf_time - length))
				vmaf_time = vmaf_previous_time + length
			end --10 seconds seems to be the magic number for vmaf, so we ensure a scene segment is at most 10 seconds.
			vmaf_pre_roll = math.min(vmaf_previous_time, length)
			vmaf_previous_time = vmaf_previous_time - vmaf_pre_roll
			previous_cq = get_vmaf(
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
				vmaf_previous_time,
				vmaf_time,
				vmaf_scene,
				previous_cq,
				vmaf_pre_roll,
				temp_folder,
				resume
			)
			command_base = base(string.format(filters.ffmpeg, vspipe_start, v[2] - 1), input, pre_roll)
		else
			previous_cq = quality
			command_base = base(
				string.gsub(string.gsub(string.format(filters.ffmpeg, "", ""), "-s", ""), "-e", ""),
				input,
				vspipe_start
			)
		end
		if not parallel then
			table.insert(output_table, previous_cq)
		else
			local intermediary_output = string.format("%s_%s.%s.%s.%s", output, v[3], "mkv", "int", "mkv")
			local final_output = string.format("%s_%s.%s", output, v[3], "mkv")
			if pl.path.isfile(final_output) then
				table.insert(output_table, final_output)
			else
				local final_command = string.format(
					[[%s %s -an -sn "%s"]],
					command_base,
					video_command(previous_cq, args, false),
					intermediary_output
				)
				table.insert(output_table, final_output)
				print(string.format("Running Command: %s", final_command))
				local count = 1
				local success
				while (not success) and count < 5 do
					count = count + 1
					success = utils.executeex(final_command)
					if success then
						break
					end
				end
				if not success then
					print(string.format("Failed to encode scene %s", v[3]))
				else
					pl.file.move(intermediary_output, final_output)
				end
			end
		end
	end
	return output_table
end
return parallel_encoding
