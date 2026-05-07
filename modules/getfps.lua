local fpsdividendtxt
local fpsdivisortxt
local fps
local fpstable
local fpsparsed
local function getfps(ffprobe)
	local fpsparsed = ffprobe.video.streams[1].avg_frame_rate
	if not fpsparsed then
		print("Could not parse fps")
	end
	fpsdividendtxt, fpsdivisortxt = string.match(fpsparsed, "(.*)%/(.*)") --filters the fps so it is only the number for certain
	if fpsdividendtxt and fpsdivisortxt then
		fpsdividendtxt = string.match(fpsdividendtxt, "%d+")
		fpsdivisortxt = string.match(fpsdivisortxt, "%d+")
		fps = fpsdividendtxt .. "/" .. fpsdivisortxt
		fpstable = {
			fps = fps,
			fpsdividendtxt = fpsdividendtxt,
			fpsdivisortxt = fpsdivisortxt,
		}
	end
	if not fpstable then
		print("Could not create the fps table")
		return "error"
	end
	return fpstable
end
return getfps
