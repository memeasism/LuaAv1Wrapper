local args = require("modules/args") --gets arguments

local gpu = require("modules/getgpu") --gets gpu

local getfilters = require("modules/getfilters")

local videocodec --prepares the videocodec

if args.video then
	videocodec = args.video
else
	videocodec = "av1"
end --checks if user set the video argument

local videocmd --prepares the videocmd

local noise = 0 --prepares the denoise level

if args.noise ~= nil then
	noise = args.noise
end --sets noise to be what the user set

local function getvideo(input, output, videoquality, filters, audiocmd)
	print(filters)
	local out
	local ffv1cmd = " -c:v ffv1 -level 3" .. " -g 1" .. " -pix_fmt yuv420p10le"
	local function cpucmd()
		local command
		if filters then
			command = filters
				.. 'av1an -i "' --av1an is only for constant frame rate, the good news is that my script saves all videos as constant frame rate, you may have to run with ffv1 before using av1 though.
				.. "-"
				.. '"'
				.. ' -o "'
				.. out
				.. '"'
				.. ' -e "aom"'
				.. " --pix-format yuv420p10le"
				.. ' -v " --cq-level='
				.. videoquality
				.. " --end-usage=q --max-reference-frames=7 --denoise-noise-level="
				.. noise
				.. '"'
				.. ' -f "'
				.. '"'
				.. ' --audio-params "'
		else
			command = 'av1an -i "' --av1an is only for constant frame rate, the good news is that my script saves all videos as constant frame rate, you may have to run with ffv1 before using av1 though.
				.. input
				.. '"'
				.. ' -o "'
				.. out
				.. '"'
				.. ' -e "aom"'
				.. " --pix-format yuv420p10le"
				.. ' -v " --cq-level='
				.. videoquality
				.. " --end-usage=q --max-reference-frames=7 --denoise-noise-level="
				.. noise
				.. '"'
				.. ' -f "'
				.. '"'
				.. ' --audio-params "'
		end
		return command
	end

	local intelcmd = " -c:v av1_qsv"
		.. " -q:v "
		.. videoquality
		.. " -preset veryslow"
		.. " -extbrc 1"
		.. " -look_ahead 1"
		.. " -look_ahead_depth 60"
		.. " -look_ahead_downsampling off"
		.. " -refs 16"
		.. " -adaptive_i 1"
		.. " -adaptive_b 1"
		.. " -low_power 0"
		.. " -pix_fmt p010le"
		.. " -vtag av01"

	--these set the commands for encoding

	if videocodec == "av1" then
		if gpu == 0 then
			for key, value in pairs(output) do
				out = value
				videocmd = cpucmd()

				os.execute(videocmd .. string.gsub(audiocmd, '"', "'") .. '"')
			end
			os.exit()
		elseif gpu == 1 then
			videocmd = intelcmd

			--[[elseif gpu == 2 then

			videocmd = amdcmd

		elseif gpu == 3 then

			videocmd = nvidiacmd]]
		end
	elseif videocodec == "ffv1" then
		videocmd = ffv1cmd
	end --sets and runs encoding commands

	return videocmd
end

return getvideo
