local args = require("modules/args") --gets arguments
local getfps = require("modules/getfps")
local ivtc_slows = {
	2, --slow
	1, --medium
	0, --fast
} --ivtc speed 1-3
local ivtc_field_orders = {
	-1, --vapoursynth default
	0, --bottom field first
	1, --top field first
} --ivtc field order 1-3
local deinterlace_preset
local deinterlace_field_order
local ivtc_slow
local ivtc_field_order
if args.ivtc_slow then
	ivtc_slow = ivtc_slows[tonumber(args.ivtc_slow)]
else
	ivtc_slow = ivtc_slows[1]
end
if args.ivtc_field then
	ivtc_field_order = ivtc_field_orders[tonumber(args.ivtc_field)]
else
	ivtc_field_order = ivtc_field_orders[1]
end
local vsscripts = {
	string.gsub(arg[0], "encoder.lua", "") .. "/VPScripts/ivtc.vpy",
	string.gsub(arg[0], "encoder.lua", "") .. "/VPScripts/di.vpy",
	string.gsub(arg[0], "encoder.lua", "") .. "/VPScripts/ivtc+di.vpy",
} --vapoursynth scripts
local function getfilters(input)
	local filters
	local fps = getfps(input)
	if fps then
		if args.telecine and args.interlaced then
			filters = "vspipe "
				.. vsscripts[3]
				.. ' -c y4m -a video="'
				.. input
				.. '" -a ivtc_slow='
				.. ivtc_slow
				.. " -a ivtc_field_order="
				.. ivtc_field_order
				.. " -a fps_divisor="
				.. fps.fpsdivisortxt
				.. " -a fps_dividend="
				.. fps.fpsdividendtxt
				.. " - | "
		elseif args.telecine then
			filters = "vspipe "
				.. vsscripts[1]
				.. ' -c y4m -a video="'
				.. input
				.. '" -a ivtc_slow='
				.. ivtc_slow
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
				.. " - | "
		else
		end --sets filters according to arguments
	else
		filters = nil
	end
	return filters
end
return getfilters
