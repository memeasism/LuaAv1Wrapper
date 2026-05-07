local function getquality(input, ffprobe, gpu, args)
	local qualityoptions = {
		cpu = {
			SD = 12,
			HD = 22,
			UHD = 24,
		}, --CPU quality options

		intel = {
			SD = 16,
			HD = 16,
			UHD = 20,
		}, --Intel GPU quality options
	}
	local videoquality = args.videoquality
	local resnumber = tonumber(ffprobe.video.streams[1].height) --sets the resolution string to a number
	if not resnumber then
		print("Failed to get resolution")
		return "error"
	end
	if not videoquality then
		if gpu == 0 then
			videoquality = "cpu"
		end
		if resnumber <= 480 then
			if gpu == 1 then
				videoquality = qualityoptions.intel.SD
			end
		elseif resnumber <= 1080 then
			if gpu == 1 then
				videoquality = qualityoptions.intel.HD
			end
		elseif resnumber <= 2160 then
			if gpu == 1 then
				videoquality = qualityoptions.intel.UHD
			end
		end
	end --sets the video quality relative to the resolution
	if not videoquality then
		print("Failed to get video quality")
		return "error"
	end
	return videoquality
end
return getquality
