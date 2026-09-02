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
	get_vmaf
)
	local output_table = {}
	local previous_cq
	local pl = require("pl.import_into")()
	local utils = pl.utils
	for i, v in ipairs(scenes) do
		if quality == false then
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
				v[1],
				v[2],
				v[3],
				previous_cq
			)
		else
			previous_cq = quality
		end
		if not parallel then
			table.insert(output_table, previous_cq)
		else
			local final_output = (string.format("%s_%s.%s", output, v[3], "mkv"))
			local final_command = string.format(
				[[%s %s -an "%s"]],
				base(string.format(filters.ffmpeg, v[1], v[2] - 1), input),
				video_command(previous_cq),
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
