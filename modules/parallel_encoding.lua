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
			local previous_time = v[1]
			local time = v[2]
			local scene = v[3]
			if time - previous_time > length then
				previous_time = math.random(previous_time, (time - length))
				time = previous_time + length
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
				previous_time,
				time,
				scene,
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
