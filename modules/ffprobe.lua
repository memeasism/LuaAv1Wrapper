local function ffprobe(input, pl, cjson)
	local video_success, video_return, video_json, video_err = pl.utils.executeex(
		'ffprobe -v quiet -print_format json -show_streams -show_format -select_streams v:0 "' .. input .. '"'
	)
	local audio_success, audio_return, audio_json, audio_err = pl.utils.executeex(
		'ffprobe -v quiet -print_format json -show_streams -show_format -select_streams a:0 "' .. input .. '"'
	)
	if not (video_success and audio_success) then
		print("Could not run ffprobe, Errors:")
		print(video_err)
		print(audio_err)
		return nil
	end
	local video_probe = cjson.decode(video_json)
	local audio_probe = cjson.decode(audio_json)
	if not (video_probe and audio_probe) then
		print("Failed to read ffprobe output")
		return nil
	end
	local probe = { video = video_probe, audio = audio_probe }
	if not probe then
		print("FFprobe failed")
		pl.utils.quit()
	end
	return probe
end
return ffprobe
