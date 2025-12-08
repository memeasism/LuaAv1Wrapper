local args = require("args") --gets arguments

local getfps = require("getfps") --use fps module

local function getfilters(input)
	local fps = getfps(input) --gets source fps

	local filters = ' -vf "fps=' .. fps.fps .. '"' --sets default filters

	if args.telecine and args.interlaced then
		filters = ' -vf "pullup, bwdif=mode=send_field, fps='
			.. tonumber(fps.fpsdividendtxt) * 2
			.. "/"
			.. tonumber(fps.fpsdivisortxt)
			.. '"'
	elseif args.telecine then
		filters = ' -vf "pullup, fps=' .. fps.fps .. '"'
	elseif args.interlaced then
		filters = ' -vf "bwdif=mode=send_field, fps='
			.. tonumber(fps.fpsdividendtxt) * 2
			.. "/"
			.. tonumber(fps.fpsdivisortxt)
			.. '"'
	end --sets filters according to arguments

	return filters
end

return getfilters
