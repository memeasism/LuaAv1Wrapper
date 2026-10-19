local function ffprobe(input, pl, cjson)
	local video_success, video_return, video_json, video_err
	local audio_success, audio_return, audio_json, audio_err
	local utils = pl.utils
	local video_command =
		string.format('ffprobe -v quiet -print_format json -show_streams -show_format -select_streams v:0 "%s"', input)
	local audio_command =
		string.format('ffprobe -v quiet -print_format json -show_streams -show_format -select_streams a:0 "%s"', input)

	for i = 1, 5 do
		if not video_success then
			video_success, video_return, video_json, video_err = utils.executeex(video_command)
		end
		if not audio_success then
			audio_success, audio_return, audio_json, audio_err = utils.executeex(audio_command)
		end
		if video_success and audio_success then
			local video_probe = cjson.decode(video_json)
			local audio_probe = cjson.decode(audio_json)
			pl.pretty(video_probe)
			pl.utils.quit()
			if not (video_probe and audio_probe) then
				print("Failed to read ffprobe output")
				return "error"
			end
			local probe = { video = video_probe, audio = audio_probe }
			if not probe then
				print("FFprobe failed")
				return "error"
			end
			return probe
		end
		if i == 5 then
			print("Could not run ffprobe, Errors:")
			print(video_err)
			print(audio_err)
			return "error"
		end
	end
end
return ffprobe
