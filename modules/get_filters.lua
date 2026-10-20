local function getfilters(input, content, fps, args, pl)
	local utils = pl.utils
	local path = pl.path
	local join = path.join
	local dirname = path.dirname
	local tablex = pl.tablex
	local filter
	local proxy
	local deinterlace_BFF
	local ivtc_BFF
	local redirect
	if path.is_windows then
		redirect = "2>nul"
	else
		redirect = "2>/dev/null"
	end
	local function formatffmpeg(str)
		local formatted
		local key, value = utils.splitv(str, "=", false)
		if not (key and value) then
			print("Failed to format filters to ffmpeg")
			return "error"
		end
		if path.isfile(value) then
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
		passthrough = utils.quote_arg(join(dirname(arg[0]), "VPScripts", "passthrough.vpy")),
		ivtc = utils.quote_arg(join(dirname(arg[0]), "VPScripts", "ivtc.vpy")),
		deinterlace = utils.quote_arg(join(dirname(arg[0]), "VPScripts", "di.vpy")),
		deinterlace_proxy = utils.quote_arg(join(dirname(arg[0]), "VPScripts", "di_proxy.vpy")),
		mixed = utils.quote_arg(join(dirname(arg[0]), "VPScripts", "ivtc+di.vpy")),
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
		ffmpeg = "vspipe " .. pl.path.normpath(vsscripts[filter]) .. " -c y4m " .. table.concat(
			pl.tablex.map(formatffmpeg, attributes[filter]),
			" "
		) .. " -s %s -e %s - " .. redirect .. " | ",
		--[[av1an = utils.quote_arg(path.normpath(vsscripts[filter]))
			.. " --vspipe-args "
			.. table.concat(pl.tablex.map(formatav1an, attributes[filter]), " "),]]
		--commented out but not removed incase I decide to go back to av1an, but don't want to waste resources formatting.
		proxy = {
			--[[av1an = utils.quote_arg(path.normpath(vsscripts[proxy]))
				.. " --vspipe-args "
				.. table.concat(pl.tablex.map(formatav1an, attributes[proxy]), " "),]]
			ffmpeg = "vspipe " .. vsscripts[filter] .. " -c y4m " .. table.concat(
				pl.tablex.map(formatffmpeg, attributes[filter]),
				" "
			) .. " -s %s -e %s - " .. redirect .. " | ",
		},
	}

	return filters
end
return getfilters
