local function getsize(input)
	local aspectprobe = io.popen(
		'ffprobe -v error -select_streams v:0 -show_entries stream=display_aspect_ratio -of default=noprint_wrappers=1:nokey=1 "'
			.. input
			.. '"'
	)
	print(
		'ffprobe -v error -select_streams v:0 -show_entries stream=display_aspect_ratio -of default=noprint_wrappers=1:nokey=1 "'
			.. input
			.. '"'
	)
	local aspect = aspectprobe:read("*l")
	aspect = aspect:gsub("%s+", "")
	aspect = aspect:gsub(":", "/")
	print(aspect)
	return aspect
end
return getsize
