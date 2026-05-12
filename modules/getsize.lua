local function getsize(input, ffprobe, pl)
	local function gcd(a, b)
		if a == 0 then
			return b
		end
		return gcd(b % a, a)
	end
	local function simplify(a, b)
		local divisor = gcd(a, b)
		local width = math.floor(a / divisor)
		local height = math.floor(b / divisor)
		return width, height
	end
	local aspectprobe = ffprobe.video.streams[1].display_aspect_ratio
	local sar = ffprobe.video.streams[1].sample_aspect_ratio
	local aspect
	local width = ffprobe.video.streams[1].width
	local height = ffprobe.video.streams[1].height
	if not aspectprobe then
		if not (width and height) then
			print("No aspect ratio or video dimensions, what is up here?")
			pl.utils.quit()
		end
		if not sar then
			print("Setting aspect ratio to the videos dimensions, neither PAR or DAR are available.")
			local dar_width, dar_height = simplify(width, height)
			aspect = dar_width .. "/" .. dar_height
			return aspect
		end
		print("DAR not found, using PAR.")
		local sar_width, sar_height = pl.utils.splitv(sar, ":", false)
		if not (sar_width and sar_height) then
			print("For some reason the sar was not actually given despite how this script functions.")
			pl.utils.quit()
		end
		sar_width = tonumber(sar_width)
		sar_height = tonumber(sar_height)
		if not (sar_width and sar_height) then
			print("For some reason the sar failed to convert into a number.")
			pl.utils.quit()
		end
		local dar_width, dar_height = simplify(width * sar_width, height * sar_width)
		aspect = dar_height .. "/" .. dar_height
		return aspect
	end
	aspect = aspectprobe:gsub(":", "/")
	return aspect
end
return getsize
