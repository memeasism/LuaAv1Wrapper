local function getfilters(input, content, fps, args, pl)
	local filter
	local proxy
	local deinterlace_BFF
	local ivtc_BFF
	local function formatffmpeg(str)
		local formatted
		local key, value = pl.utils.splitv(str, "=", false)
		if not (key and value) then
			print("Failed to format filters to ffmpeg")
			return "error"
		end
		if pl.utils.readfile(value) then
			formatted = "-a " .. key .. "=" .. pl.utils.quote_arg(value)
			return formatted
		end
		formatted = "-a " .. key .. "=" .. value
		return formatted
	end
	local function formatav1an(str)
		local formatted
		formatted = pl.utils.quote_arg(str)
		if not formatted then
			print("Failed to format filters to av1an")
		end
		return formatted
	end
	if not content then
		print("Content type is unavailable")
		return "error"
	end
	if string.find(content, "Progressive") then
		filter = "passthrough"
		proxy = "passthrough"
	end
	if string.find(content, "Telecined") then
		filter = "ivtc"
		proxy = "ivtc"
		if string.find(content, "TFF") then
			ivtc_BFF = "False"
		end
		if string.find(content, "BFF") then
			ivtc_BFF = "True"
		end
	end
	if string.find(content, "Interlaced") then
		filter = "deinterlace"
		proxy = "deinterlace_proxy"
		if string.find(content, "TFF") then
			deinterlace_BFF = "False"
		end
		if string.find(content, "BFF") then
			deinterlace_BFF = "True"
		end
	end
	if string.find(content, "Mixed") then
		filter = "mixed"
		proxy = "ivtc"
		if string.find(content, "TFF") then
			ivtc_BFF = "False"
			deinterlace_BFF = "True"
		end
		if string.find(content, "BFF") then
			ivtc_BFF = "True"
			deinterlace_BFF = "False"
		end
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

	local vsscripts = {
		passthrough = pl.utils.quote_arg(string.gsub(arg[0], "encoder.lua", "") .. "/VPScripts/passthrough.vpy"),
		ivtc = pl.utils.quote_arg(string.gsub(arg[0], "encoder.lua", "") .. "/VPScripts/ivtc.vpy"),
		deinterlace = pl.utils.quote_arg(string.gsub(arg[0], "encoder.lua", "") .. "/VPScripts/di.vpy"),
		deinterlace_proxy = pl.utils.quote_arg(string.gsub(arg[0], "encoder.lua", "") .. "/VPScripts/di_proxy.vpy"),
		mixed = pl.utils.quote_arg(string.gsub(arg[0], "encoder.lua", "") .. "/VPScripts/ivtc+di.vpy"),
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
			pl.tablex.map(formatffmpeg, attributes[filter]),
			" "
		) .. " - | ",
		av1an = pl.utils.quote_arg(vsscripts[filter])
			.. " --vspipe-args "
			.. table.concat(pl.tablex.map(formatav1an, attributes[filter]), " "),
		proxy = {
			av1an = pl.utils.quote_arg(vsscripts[proxy])
				.. " --vspipe-args "
				.. table.concat(pl.tablex.map(formatav1an, attributes[proxy]), " "),
			ffmpeg = "vspipe " .. vsscripts[filter] .. " -c y4m " .. table.concat(
				pl.tablex.map(formatffmpeg, attributes[filter]),
				" "
			) .. " - | ",
		},
	}

	return filters
end
return getfilters
