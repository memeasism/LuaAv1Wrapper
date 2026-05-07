local function getaudio(input, ffprobe, args)
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
		local string = " -c:a libopus"
			.. ' -af aformat=channel_layouts="7.1|5.1|stereo"'
			.. " -mapping_family 1"
			.. " -b:a "
			.. bitrate
			.. " -vbr on"
			.. " -compression_level 7"
		return string
	end
	local flaccmd = " -c:a flac"
		.. ' -af aformat=channel_layouts="7.1|5.1|stereo"'
		.. " -mapping_family 1"
		.. " -compression_level 12"
	--these set the commands for encoding
	local audioprobe = ffprobe.audio.streams[1]
	if args.audiobitrate then
		audiobitrate = args.audiobitrate
	end --sets audio to the argument value
	if not audioprobe.codec_name then
		print("Unable to find audio codec name")
		return "error"
	end
	if audiocodec == nil then
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
	if audiocodec == "opus" and audiobitrate == 0 then
		if not audioprobe.bit_rate then
			print("Could not find original audio bitrate, setting to safe default")
			audiobitrate = 360000
		end
		if string.find(audioprobe.codec_name, "opus") then
			oldcodec = "opus"
		end --checks if original codec was opus
		if oldcodec == "opus" then
			audiopass = true
		else
			audiobitrate = audioprobe.bit_rate / 2
			print(audiobitrate)
		end
	end --decides bitrate and whether or not to just pass audio through.
	if audiopass ~= true then
		if audiocodec == "opus" then
			audiocmd = opuscmd(audiobitrate)
		end
		if audiocodec == "flac" then
			audiocmd = flaccmd
		end --sets audiocmd
	else
		audiocmd = passcmd
	end
	if not audiocmd then
		print("I dont know what went wrong")
		return "error"
	end
	return audiocmd
end
return getaudio
