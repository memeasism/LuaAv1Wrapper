local function getfilters(input)
	print("Analysing first 5 minutes of video, please wait!")
	local fields = io.popen('ffmpeg -i "' .. input .. '" -filter:v idet -t 300 -an -f null - 2>&1') --analyse the first 5 minutes to determine if content is telecine, interlaced, progressive, or a mix!
	local content
	local line
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
	if tff and bff == 0 then
		content = "Progressive"
	end
	if tff and bff ~= 0 then
		content = "?"
	end
	if content ~= "?" then
		return content
	end
	if tff or bff > progressive then
		content = "Interlaced"
	else
		content = "Telecined"
	end
	if content == "Interlaced" then
		if tff > bff then
			if progressive > 0 then
				content = "Mixed TFF"
			else
				content = "Interlaced TFF"
			end
		end
		if bff > tff then
			if progressive > 0 then
				content = "Mixed BFF"
			else
				content = "Interlaced BFF"
			end
		end
	end
	if content == "Telecined" then
		if tff > bff then
			if progressive > 0 then
				content = "Mixed TFF"
			else
				content = "Telecined TFF"
			end
		end
		if bff > tff then
			if progressive > 0 then
				content = "Mixed BFF"
			else
				content = "Telecined BFF"
			end
		end
	end
	if not content then
		print("I don't know what went wrong")
		return "error"
	end
	return content
end
return getfilters
