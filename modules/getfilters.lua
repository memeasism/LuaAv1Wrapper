local args = require("args") --gets arguments

local deinterlace_presets = {
	'"Placebo"',
	'"Very Slow"',
	'"Slower"',
	'"Slow"',
	'"Medium"',
	'"Fast"',
	'"Faster"',
	'"Very Fast"',
	'"Super Fast"',
	'"Ultra Fast"',
	'"Draft"',
} --qtgmc preset, 1-11

local deinterlace_field_orders = {
	-1, --vapoursynth default
	0, --bottom field first
	1, --top field first
} --qtgmc field order 1-3

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

deinterlace_preset = deinterlace_presets[3]

deinterlace_field_order = deinterlace_field_orders[1]

ivtc_slow = ivtc_slows[1]

ivtc_field_order = ivtc_field_orders[1]

local vsscripts = {
	"./VPScripts/ivtc.vpy",
	"./VPScripts/di.vpy",
	"./VPScripts/ivtc+di.vpy",
} --vapoursynth scripts

local function getfilters(input)
	local filters

	if args.telecine and args.interlaced then
		filters = "vspipe "
			.. vsscripts[3]
			.. ' -c y4m -a video="'
			.. input
			.. '" -a deinterlace_preset='
			.. deinterlace_preset
			.. " -a deinterlace_field_order="
			.. deinterlace_field_order
			.. " -a ivtc_slow="
			.. ivtc_slow
			.. " -a ivtc_field_order="
			.. ivtc_field_order
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
			.. " - | "
	elseif args.interlaced then
		filters = "vspipe "
			.. vsscripts[2]
			.. ' -c y4m -a video="'
			.. input
			.. '" -a deinterlace_preset='
			.. deinterlace_preset
			.. " -a deinterlace_field_order="
			.. deinterlace_field_order
			.. " - | "
	end --sets filters according to arguments

	return filters
end

return getfilters
