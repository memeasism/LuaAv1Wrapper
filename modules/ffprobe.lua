local cjson = require("cjson")
local function ffprobe(input)
	local video_command =
		io.popen('ffprobe -v quiet -print_format json -show_streams -show_format -select_streams v:0 "' .. input .. '"')
	local audio_command =
		io.popen('ffprobe -v quiet -print_format json -show_streams -show_format -select_streams a:0 "' .. input .. '"')
	if not (video_command and audio_command) then
		print("Could not run ffprobe")
		return "error"
	end
	local video_json = video_command:read("*a")
	local audio_json = audio_command:read("*a")
	video_command:close()
	audio_command:close()
	if not (video_json and audio_json) then
		print("FFprobe was empy")
		return "error"
	end
	local video_probe = cjson.decode(video_json)
	local audio_probe = cjson.decode(audio_json)
	if not (video_probe and audio_probe) then
		print("Failed to read ffprobe output")
	end
	local probe = { video = video_probe, audio = audio_probe }
	if not probe then
		print("FFprobe failed")
		return "error"
	end
	return probe
end
return ffprobe
