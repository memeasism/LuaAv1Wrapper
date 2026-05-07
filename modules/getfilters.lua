local function getfilters(input, content, fps, args, pl)
	local filter
	local proxy
	local deinterlace_BFF
	local ivtc_BFF
	local utils = pl.utils
	local tablex = pl.tablex
	local function formatffmpeg(str)
		local formatted
		local key, value = utils.splitv(str, "=", false)
		if not (key and value) then
			print("Failed to format filters to ffmpeg")
			return "error"
		end
		if utils.readfile(value) then
			formatted = "-a " .. key .. "=" .. utils.quote_arg(value)
			return formatted
		end
		formatted = "-a " .. key .. "=" .. value
		return formatted
	end
	local function formatav1an(str)
		local formatted
		formatted = utils.quote_arg(str)
		if not formatted then
			print("Failed to format filters to av1an")
		end
		return formatted
	end
	if args.ivtc_bff then
		ivtc_BFF = "False"
	else
		ivtc_BFF = "True"
	end
	if args.deinterlace_bff then
		deinterlace_BFF = "False"
	else
		deinterlace_BFF = "True"
	end
	if not args.telecine or args.interlaced then
		if not content then
			print("Content type is unavailable")
			return "error"
		end
		if string.find(content, "Progressive") then
			filter = "passthrough"
			proxy = "passthrough"
			print("Passing through")
		end
		if string.find(content, "Telecined") then
			filter = "ivtc"
			proxy = "ivtc"
			print("Using ivtc filter")
			if string.find(content, "TFF") then
				ivtc_BFF = "False"
				print("TFF")
			end
			if string.find(content, "BFF") then
				ivtc_BFF = "True"
				print("BFF")
			end
		end
		if string.find(content, "Interlaced") then
			filter = "deinterlace"
			proxy = "deinterlace_proxy"
			print("Using deinterlace filter")
			if string.find(content, "TFF") then
				deinterlace_BFF = "False"
				print("TFF")
			end
			if string.find(content, "BFF") then
				deinterlace_BFF = "True"
				print("BFF")
			end
		end
		if string.find(content, "Mixed") then
			filter = "mixed"
			proxy = "ivtc"
			print("Using mixed filter")
			if string.find(content, "TFF") then
				ivtc_BFF = "False"
				deinterlace_BFF = "True"
				print("TFF")
			end
			if string.find(content, "BFF") then
				ivtc_BFF = "True"
				deinterlace_BFF = "False"
				print("BFF")
			end
		end
	end

	local vsscripts = {
		passthrough = utils.quote_arg(string.gsub(arg[0], "encoder.lua", "") .. "/VPScripts/passthrough.vpy"),
		ivtc = utils.quote_arg(string.gsub(arg[0], "encoder.lua", "") .. "/VPScripts/ivtc.vpy"),
		deinterlace = utils.quote_arg(string.gsub(arg[0], "encoder.lua", "") .. "/VPScripts/di.vpy"),
		deinterlace_proxy = utils.quote_arg(string.gsub(arg[0], "encoder.lua", "") .. "/VPScripts/di_proxy.vpy"),
		mixed = utils.quote_arg(string.gsub(arg[0], "encoder.lua", "") .. "/VPScripts/ivtc+di.vpy"),
	} --vapoursynth scripts
	local attributes = {
		passthrough = {
			"video=" .. input,
			"fps_divisor=" .. fps.fpsdivisortxt,
			"fps_dividend=" .. fps.fpsdividendtxt,
		},
		ivtc = {
			"video=" .. input,
			"fps_divisor=" .. fps.fpsdivisortxt,
			"fps_dividend=" .. fps.fpsdividendtxt,
			"IVTC_value=" .. ivtc_BFF,
		},
		deinterlace = {
			"video=" .. input,
			"fps_divisor=" .. fps.fpsdivisortxt,
			"fps_dividend=" .. fps.fpsdividendtxt,
			"DI_value=" .. deinterlace_BFF,
		},
		deinterlace_proxy = {
			"video=" .. input,
			"fps_divisor=" .. fps.fpsdivisortxt,
			"fps_dividend=" .. fps.fpsdividendtxt,
			"DI_value=" .. deinterlace_BFF,
		},
		mixed = {
			"video=" .. input,
			"fps_divisor=" .. fps.fpsdivisortxt,
			"fps_dividend=" .. fps.fpsdividendtxt,
			"IVTC_value=" .. ivtc_BFF,
			"DI_value=" .. deinterlace_BFF,
		},
	}
	if not (vsscripts[filter] and attributes[filter]) then
		print("Failed to pull filters from table")
		return "error"
	end
	local filters = {
		ffmpeg = "vspipe " .. vsscripts[filter] .. " -c y4m " .. table.concat(
			tablex.map(formatffmpeg, attributes[filter]),
			" "
		) .. " - | ",
		av1an = utils.quote_arg(vsscripts[filter])
			.. " --vspipe-args "
			.. table.concat(tablex.map(formatav1an, attributes[filter]), " "),
		proxy = utils.quote_arg(vsscripts[proxy])
			.. " --vspipe-args "
			.. table.concat(tablex.map(formatav1an, attributes[proxy]), " "),
	}
	print(filters.ffmpeg)
	print(filters.av1an)

	--[[if fps then
		if args.telecine and args.interlaced then
			filters = "vspipe "
				.. vsscripts[3]
				.. ' -c y4m -a video="'
				.. input
				.. " -a ivtc_field_order="
				.. ivtc_field_order
				.. " -a fps_divisor="
				.. fps.fpsdivisortxt
				.. " -a fps_dividend="
				.. fps.fpsdividendtxt
				.. " -a deinterlace_bff="
				.. deinterlace_BFF
				.. '" - | '
		elseif args.telecine then
			filters = "vspipe "
				.. vsscripts[1]
				.. ' -c y4m -a video="'
				.. input
				.. " -a ivtc_field_order="
				.. ivtc_field_order
				.. " -a fps_divisor="
				.. fps.fpsdivisortxt
				.. " -a fps_dividend="
				.. fps.fpsdividendtxt
				.. " - | "
		elseif args.interlaced then
			filters = "vspipe "
				.. vsscripts[2]
				.. ' -c y4m -a video="'
				.. input
				.. '" -a fps_divisor='
				.. fps.fpsdivisortxt
				.. " -a fps_dividend="
				.. fps.fpsdividendtxt
				.. " -a deinterlace_bff="
				.. deinterlace_BFF
				.. ' -a deinterlace_preset="'
				.. deinterlace_preset
				.. '" - | '
		else
		end --sets filters according to arguments
	else
		filters = nil
	end]]
	return filters
end
return getfilters
