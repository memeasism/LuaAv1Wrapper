local function get_colors(ffprobe)
	local video_stream = ffprobe.video.streams[1]
	local colors = {
		video_stream.color_primaries or "bt709",
		video_stream.color_range or "tv",
		video_stream.color_space or "bt709",
		video_stream.color_transfer or "bt709",
	}
	for color in ipairs(colors) do
		if not color then
			return "error"
		end
	end
	local color_filters = string.format(
		"setparams=color_primaries=%s:range=%s:colorspace=%s:color_trc=%s",
		colors[1],
		colors[2],
		colors[3],
		colors[4]
	)
	return color_filters
end
return get_colors
