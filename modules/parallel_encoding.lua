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
	fps_number
)
	local length = math.floor((fps_number * 10) + 0.5) --find vmaf bases upon 10 second segments of a scene, this works pretty great since scene have to be uniform enough throughout to not be detected as a new one.
	local output_table = {}
	local previous_cq
	local pl = require("pl.import_into")()
	local utils = pl.utils
	local command_base
	for i, v in ipairs(scenes) do
		if quality == false then
			local vmaf_previous_time = v[1]
			local vmaf_time = v[2]
			local vmaf_scene = v[3]
			if vmaf_time - vmaf_previous_time > length then
				vmaf_previous_time = math.random(vmaf_previous_time, (vmaf_time - length))
				vmaf_previous_timetime = vmaf_previous_time + length
			end
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
				previous_cq
			)
			command_base = base(string.format(filters.ffmpeg, v[1], v[2] - 1), input)
		else
			previous_cq = quality
			command_base =
				base(string.gsub(string.gsub(string.format(filters.ffmpeg, "", ""), "-s", ""), "-e", ""), input)
		end
		if not parallel then
			table.insert(output_table, previous_cq)
		else
			local final_output = (string.format("%s_%s.%s", output, v[3], "mkv"))
			local final_command = string.format(
				[[%s %s -an -sn "%s"]],
				command_base,
				video_command(previous_cq, args, false),
				final_output
			)
			table.insert(output_table, final_output)
			print(string.format("Running Command: %s", final_command))
			utils.execute(final_command)
		end
	end
	return output_table
end
return parallel_encoding
