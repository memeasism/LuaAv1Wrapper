local args = require("modules/args") --gets arguments

local gpu = require("modules/getgpu")

local qualityoptions = {

	cpu = {
		SD = 12,
		HD = 22,
		UHD = 24,
	}, --CPU quality options

	intel = {
		SD = 18,
		HD = 18,
		UHD = 22,
	}, --Intel GPU quality options
}

local videoquality = args.videoquality

local function getquality(input)
	local resolution =
		io.popen('ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=s=x:p=0 "' .. input .. '"') --gets resolution from video

	local resparsed = resolution:read("*a") --reads resolution

	local resstring = string.gsub(resparsed, "%D+", "") --filters to get only the number

	local resnumber = tonumber(resstring) --sets the resolution string to a number

	if videoquality == nil then
		if resnumber >= 480 then
			if gpu == 1 then
				videoquality = qualityoptions.intel.SD
			elseif gpu == 0 then
				videoquality = qualityoptions.cpu.SD
			end
		elseif resnumber >= 1080 then
			if gpu == 1 then
				videoquality = qualityoptions.intel.HD
			elseif gpu == 0 then
				videoquality = qualityoptions.cpu.SD
			end
		elseif resnumber >= 2160 then
			if gpu == 1 then
				videoquality = qualityoptions.intel.UHD
			elseif gpu == 0 then
				videoquality = qualityoptions.cpu.SD
			end
		end
	end --sets the video quality relative to the resolution

	return videoquality
end

return getquality
