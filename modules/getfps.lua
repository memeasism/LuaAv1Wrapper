local fpsdividendtxt
local fpsdivisortxt
local fps
local fpstable
local fpsparsed
local function getfps(input)
	local fpscmd = io.popen(
		'ffprobe -v error -select_streams v:0 -show_entries stream=avg_frame_rate -of default=noprint_wrappers=1:nokey=1 "'
			.. input
			.. '"'
	) --command to get the fps of the source video
	fpsparsed = fpscmd:read("*a") --reads the fps
	print(fpsparsed)
	if fpsparsed then
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
	end
	if fpstable then
		return fpstable
	end
end
return getfps
