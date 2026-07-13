local function getaudio(input, output, no_flac_extensions, ffprobe, args, pl)
	local losslesscodecs = {
		"pcm",
		"flac",
		"dts-hd",
		"alac",
		"truehd",
	} --list of lossless codecs the source can be
	local lossycodecs = {
		"opus",
		"ac3",
		"aac",
		"dts",
		"mpeg",
	} --list of lossy codecs the source can be
	local audiocmd --prepares the audiocmd
	local audiopass --prepares if the audio is passed
	local audiocodec = args.audio --sets codec
	local oldcodec --prepares oldcodec
	local audiobitrate = 0 --prepares bitrate
	local passcmd = " -c:a copy" --the command used if audio is to be passed
	local function opuscmd(bitrate)
		local command = string.format(
			[[-c:a libopus -af aformat=channel_layouts="7.1|5.1|stereo" -mapping_family 1 -b:a %s -vbr on -compression_level 7]],
			bitrate
		)
		return command
	end
	local flaccmd = [[-c:a flac -af aformat=channel_layouts="7.1|5.1|stereo" -mapping_family 1 -compression_level 7]]
	--these set the commands for encoding
	local audioprobe = ffprobe.audio.streams[1]
	if args.audiobitrate then
		audiobitrate = args.audiobitrate
	end --sets audio to the argument value
	if not audioprobe then
		print("Unable to find audio stream assuming there is no audio track")
		audiopass = true
		audiocodec = true
	end
	if not audiocodec then
		if not audioprobe.codec_name then
			print("Could not find audio codec name")
			return "error"
		end
		for k, v in pairs(losslesscodecs) do
			if string.find(audioprobe.codec_name, v) then
				audiocodec = "flac"
				break
			end
		end
		if audiocodec == nil then
			for k, v in pairs(lossycodecs) do
				if string.find(audioprobe.codec_name, v) then
					audiocodec = "opus"
					oldcodec = v
					break
				end
			end
		end
		if audiocodec == nil then
			print("couldn't find a programmed codec, passing through instead.")
			audiopass = true
		end
	end --checks and sets audio codec
	if audiocodec ~= "opus" and audiobitrate == 0 then
		if not audioprobe.bit_rate then
			print("Could not find original audio bitrate, setting to safe default")
			audiobitrate = 128000
		else
		if string.find(audioprobe.codec_name, "opus") then
			oldcodec = "opus"
		end --checks if original codec was opus
		if oldcodec == "opus" then
			audiopass = true
		else
			audiobitrate = audioprobe.bit_rate / 2
		end
	end --decides bitrate and whether or not to just pass audio through.
end
	if not audiopass then
		if audiocodec == "opus" then
			audiocmd = opuscmd(audiobitrate)
		end
		if audiocodec == "flac" then
			local output_format = pl.path.extension(output)
			for key, value in pairs(no_flac_extensions) do
				if string.match(output_format, value) then
					local output_no_ext = string.match(output, string.format([[(.*)%s]], output_format))
					print(output_no_ext)
					output = string.format([[%s.%s]], output_no_ext, "mkv")
					print(output)
					break
				end
			end
			if output_format == ".webm" then
			end
			audiocmd = flaccmd
		end --sets audiocmd
	else
		audiocmd = passcmd
	end
	if not audiocmd then
		print("I dont know what went wrong")
		return "error"
	end
	return audiocmd, output
end
return getaudio
