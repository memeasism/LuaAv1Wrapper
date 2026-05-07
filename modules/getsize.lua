local function getsize(input, ffprobe)
	local aspectprobe = ffprobe.video.streams[1].display_aspect_ratio
	local aspect
	if not aspectprobe then
		print("DAR not found, settling for PAR")
		aspect = "1/1"
		return aspect
	end
	aspect = aspectprobe:gsub(":", "/")
	return aspect
end
return getsize
