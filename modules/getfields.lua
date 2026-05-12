local function getfilters(input, args)
	local line
	local content
	if not (args.progressive or args.ivtc_bff or args.deinterlace_bff) then
		print("Analysing first 5 minutes of video, please wait!")
		local fields = io.popen('ffmpeg -i "' .. input .. '" -filter:v idet -t 300 -an -f null - 2>&1') --analyse the first 5 minutes to determine if content is telecine, interlaced, progressive, or a mix!
		if not fields then
			print("The script failed to even analyse the field order")
			return "error"
		end
		for lines in fields:lines() do
			if string.match(lines, "Single frame detection:%s*TFF:%s*(%d+)") then
				line = lines
			end
		end
		fields:close()
		if not line then
			print("Failed to find the line that tells the field order")
			return "error"
		end
		local tff = tonumber(string.match(line, "TFF:%s*(%d+)"))
		local bff = tonumber(string.match(line, "BFF:%s*(%d+)"))
		local progressive = tonumber(string.match(line, "Progressive:%s*(%d+)"))
		if not (tff and bff and progressive) then
			print("Failed to convert fields into numbers")
			return "error"
		end
		local total = tff + bff + progressive
		local progressive_ratio = progressive / total
		local tff_ratio = tff / total
		local bff_ratio = bff / total
		print(progressive_ratio)
		print(tff_ratio)
		print(bff_ratio)
		if progressive_ratio > 0.9 then
			content = "Progressive"
		elseif
			((math.max(tff_ratio, bff_ratio) + progressive_ratio) >= 0.9)
			and (
				math.min(tff_ratio, bff_ratio) <= 0.002 --[[I find that this value workls good for mixed content]]
			)
		then
			content = "Telecined"
			if tff > bff then
				content = string.format([[%s %s]], content, "TFF")
			else
				content = string.format([[%s %s]], content, "BFF")
			end
		elseif (tff_ratio + bff_ratio) > 0.8 and progressive_ratio < 0.1 then
			content = "Interlaced"
			if tff > bff then
				content = string.format([[%s %s]], content, "TFF")
			else
				content = string.format([[%s %s]], content, "BFF")
			end
		else
			content = "Mixed"
			if tff > bff then
				content = string.format([[%s %s]], content, "TFF")
			else
				content = string.format([[%s %s]], content, "BFF")
			end
		end --picks the field types with a 90% certainty, is not perfect!
	end
	if args.ivtc_bff then
		content = "Telecined BFF"
	end
	if args.deinterlace_bff then
		content = "Interlaced BFF"
	end
	if args.interlaced and args.telecined then
		if args.deinterlace_bff then
			content = "Mixed TFF"
		end
		if args.ivtc_bff then
			content = "Mixed BFF"
		end
	end
	if args.progressive then
		content = "Progressive"
	end
	if not content then
		print("I don't know what went wrong")
		return "error"
	end
	print(line)
	print(content)
	return content
end
return getfilters
