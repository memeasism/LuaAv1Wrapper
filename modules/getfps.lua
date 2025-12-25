local function getfps(input)
	local fpscmd = io.popen(
		'ffprobe -v error -select_streams v:0 -show_entries stream=avg_frame_rate -of default=noprint_wrappers=1:nokey=1 "'
			.. input
			.. '"'
	) --command to get the fps of the source video
	local fpsparsed = fpscmd:read("*a") --reads the fps
	local fpsdividendtxt, fpsdivisortxt = string.match(fpsparsed, "(.*)%/(.*)") --filters the fps so it is only the number for certain
	fpsdividendtxt = string.match(fpsdividendtxt, "%d+")
	fpsdivisortxt = string.match(fpsdivisortxt, "%d+")
	local fps = fpsdividendtxt .. "/" .. fpsdivisortxt
	local fpstable = {
		fps = fps,
		fpsdividendtxt = fpsdividendtxt,
		fpsdivisortxt = fpsdivisortxt,
	}
	return fpstable
end
return getfps
