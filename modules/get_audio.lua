local function get_audio(input, output, no_flac_extensions, ffprobe, args, pl)
	local passcodecs = {
		"flac",
		"dts",
		"opus",
		"truehd",
	} --obviously pass flac and opus, but also, dts has been giving me issues, so we pass instead
	local problemcodecs = {
		"dts",
	}
	local losslesscodecs = {
		"pcm",
		"alac",
	} --list of lossless codecs the source can be
	local lossycodecs = {
		"ac3",
		"aac",
		"mpeg",
	} --list of lossy codecs the source can be
	local audio_command --prepares the audiocmd
	local audio_pass --prepares if the audio is passed
	local audio_codec = args.audio or nil --sets codec
	local pass_command = " -c:a copy" --the command used if audio is to be passed
	local function opus_command(bitrate)
		local command = string.format(
			[[-c:a libopus -af aformat=channel_layouts="7.1|5.1|stereo",asetpts=PTS-STARTPTS -mapping_family 1 -b:a %s -vbr on -compression_level 7]],
			bitrate
		)
		return command
	end
	local flac_command =
		[[-c:a flac -af aformat=channel_layouts="7.1|5.1|stereo",asetpts=PTS-STARTPTS -mapping_family 1 -compression_level 7]]
	--these set the commands for encoding
	local audio_probe = ffprobe.audio.streams[1]
	if not audio_probe then
		print("Unable to find audio stream assuming there is no audio track")
		return pass_command, output
	end
	local codec_name = audio_probe.codec_name
	if not codec_name then
		print("Could not find audio codec name")
		return "error"
	end
	local audio_bitrate = args.audiobitrate or 384000
	if audio_probe.bit_rate then
		audio_bitrate = tonumber(audio_probe.bit_rate) / 2
	end
	if not audio_bitrate then
		print("Could not find audio bitrate")
		return "error"
	end

	for k, v in pairs(passcodecs) do
		if codec_name:find(v) then
			audio_pass = true
			audio_codec = "pass"
			for l, w in pairs(problemcodecs) do
				if codec_name:find(w) then
					pass_command = string.format("%s -copytb 0 -max_interleave_delta 0", pass_command)
				end
			end
			break
		end
	end
	if not audio_codec then
		for k, v in pairs(losslesscodecs) do
			if codec_name:find(v) then
				audio_codec = "flac"
				break
			end
		end
	end
	if not audio_codec then
		for k, v in pairs(lossycodecs) do
			if codec_name:find(v) then
				audio_codec = "opus"
				audio_command = opus_command(audio_bitrate)
				break
			end
		end
	end
	if audio_codec == nil then
		print("couldn't find a programmed codec, passing through instead.")
		audio_pass = true
		audio_codec = "pass"
	end
	--sets audio codec

	if audio_codec == "flac" then
		local output_format = pl.path.extension(output)
		for key, value in pairs(no_flac_extensions) do
			if string.match(output_format, value) then
				local output_no_ext = string.match(output, string.format([[(.*)%s]], output_format))
				output = string.format([[%s.%s]], output_no_ext, "mkv")
				break
			end
		end
		audio_command = flac_command
	end --sets audio_command
	if audio_codec == "pass" then
		audio_command = pass_command
	end
	if not audio_command then
		print("I dont know what went wrong")
		return "error"
	end
	return audio_command, output
end
return get_audio
