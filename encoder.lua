local args = require("args") --gets arguments

local gpu = require("getgpu") --gets gpu

local getfilters = require("getfilters") --sets function modules

local getquality = require("getquality")

local getaudio = require("getaudio")

local getvideo = require("getvideo")

if args.input and args.output ~= nil then
	local input = string.gsub(args.input, "\\", "/") --sets input

	local output = string.gsub(args.output, "\\", "/") --sets output

	local filters = getfilters(input) --gets filters

	local videoquality = getquality(input) --gets quality

	local audiocmd = getaudio(input) --gets audiocmd

	local videocmd = getvideo(input, output, videoquality, filters, audiocmd) --gets videocmd

	local base = 'ffmpeg -i "' .. input .. '"' .. " -map 0:v:0" .. " -map 0:a?" .. " -map 0:s?" .. " -c:s copy" --the base of the ffmpeg command

	print(base .. filters .. videocmd .. audiocmd .. ' "' .. output .. '"') --prints command

	os.execute(base .. filters .. videocmd .. audiocmd .. ' "' .. output .. '"') --executes command
else
	print("you have to supply and input and output") --let user know they have to supply info to the script
end
