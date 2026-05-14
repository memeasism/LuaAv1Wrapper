local function getquality(input, ffprobe, gpu, args, pl)
	local videoquality
	local qualityoptions = {
		cpu = {
			SD = 12,
			HD = 4,
			UHD = 8,
		}, --CPU quality options

		intel = {
			SD = 6,
			HD = 10,
			UHD = 10,
		}, --Intel GPU quality options
	}
	local resnumber = tonumber(ffprobe.video.streams[1].height) --sets the resolution string to a number
	if not videoquality then
		if not resnumber then
			print("Failed to get resolution to set quality")
			pl.utils.quit()
		end
		if resnumber <= 480 then
			if gpu == 0 then
				videoquality = qualityoptions.cpu.SD
			end
			if gpu == 1 then
				videoquality = qualityoptions.intel.SD
			end
		elseif resnumber <= 1080 then
			if gpu == 0 then
				videoquality = qualityoptions.cpu.HD
			end
			if gpu == 1 then
				videoquality = qualityoptions.intel.HD
			end
		elseif resnumber <= 2160 then
			if gpu == 0 then
				videoquality = qualityoptions.cpu.UHD
			end
			if gpu == 1 then
				videoquality = qualityoptions.intel.UHD
			end
		end
	end --sets the video quality relative to the resolution
	if not videoquality then
		print("Failed to get video quality, setting safe default")
		if gpu == 0 then
			videoquality = qualityoptions.cpu.UHD
		end
		if gpu == 1 then
			videoquality = qualityoptions.intel.UHD
		end
	end
	return videoquality
end
return getquality
