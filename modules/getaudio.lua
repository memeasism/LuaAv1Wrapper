local args = require("args") --gets arguments

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

local opuscmd = " -c:a libopus"
	.. ' -af aformat=channel_layouts="7.1|5.1|stereo"'
	.. " -mapping_family 1"
	.. " -b:a "
	.. audiobitrate
	.. " -vbr on"
	.. " -compression_level 7"

local flaccmd = " -c:a flac"
	.. ' -af aformat=channel_layouts="7.1|5.1|stereo"'
	.. " -mapping_family 1"
	.. " -compression_level 12"

--these set the commands for encoding

local function getaudio(input)
	if args.audiobitrate ~= nil then
		audiobitrate = args.audiobitrate
	end --sets audio to the argument value

	if audiocodec == nil then
		local audioprobe = io.popen(
			'ffprobe -v error -select_streams a -show_entries stream=codec_name -of default=noprint_wrappers=1 "'
				.. input
				.. '"'
		) --gets the source codec

		local parsedprobe = audioprobe:read("*a") --reads the source codec

		for k, v in pairs(losslesscodecs) do
			if string.find(parsedprobe, v) then
				audiocodec = "flac"

				break
			end
		end

		if audiocodec == nil then
			for k, v in pairs(lossycodecs) do
				if string.find(parsedprobe, v) then
					audiocodec = "opus"

					oldcodec = v

					break
				end
			end
		end

		if audiocodec == nil then
			print("couldn't find a programmed codec.")

			os.exit()
		end
	end --checks and sets audio codec

	if audiocodec == "opus" and audiobitrate == 0 then
		local audioprobe = io.popen(
			'ffprobe -v error -select_streams a -show_entries stream=codec_name -of default=noprint_wrappers=1 "'
				.. input
				.. '"'
		) --checks source codec

		local parsedprobe = audioprobe:read("*a") --reads source bitrate

		if string.find(parsedprobe, "opus") then
			oldcodec = "opus"
		end --checks if original codec was opus

		local sourcebitrates = io.popen(
			'ffprobe -v error -select_streams a -show_entries stream=bit_rate -of default=noprint_wrappers=1 "'
				.. input
				.. '"'
		) --checks source bitrate

		local sourceparse = sourcebitrates:read("*a") --reads source bitrate

		local bitratetable = {} --sets a table for all the possible bitrates that ffmpeg reads

		for bitratestring in string.gmatch(sourceparse, "bit_rate=(%d+)") do
			local bitratenumber = tonumber(bitratestring)

			if bitratenumber then
				table.insert(bitratetable, bitratenumber)
			end
		end --puts all bitrates in a table

		if oldcodec == "opus" then
			audiopass = true
		else
			local maxbitrate = math.max(table.unpack(bitratetable))

			audiobitrate = maxbitrate / 2
		end
	end --decides bitrate and whether or not to just pass audio through.

	if audiocodec == "opus" then
		if audiopass == true then
			audiocmd = passcmd
		else
			audiocmd = opuscmd
		end
	elseif audiocodec == "flac" then
		audiocmd = flaccmd
	end --sets audiocmd

	return audiocmd
end

return getaudio
