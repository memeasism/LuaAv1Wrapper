local function count_frames(input, pl)
	local ffprobe_command = string.format(
		[[ffprobe -v error -count_frames -thread_type frame -threads auto -select_streams v:0 -show_entries stream=nb_read_frames -of default=noprint_wrappers=1:nokey=1 "%s"]],
		input
	)
	local count_success, count_return, count_frames, count_err = pl.utils.executeex(ffprobe_command)
	if count_success then
		local frame_count = tonumber(count_frames)
		return frame_count
	else
		return nil
	end
end
return count_frames
