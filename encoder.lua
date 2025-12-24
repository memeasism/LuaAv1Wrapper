local lfs = require("lfs")

local args = require("modules/args") --gets arguments

local gpu = require("modules/getgpu") --gets gpu

local getfilters = require("modules/getfilters") --sets function modules

local getquality = require("modules/getquality")

local getaudio = require("modules/getaudio")

local getvideo = require("modules/getvideo")

if args.input and args.output ~= nil then

  local parseinput = lfs.attributes(args.input)



	local input = lfs.currentdir() .. "/" .. args.input --sets input as the full path to fix any errors vspipe may have

	local output = args.output --sets output

	local filters = getfilters(input) --gets filters

	local videoquality = getquality(input) --gets quality

	local audiocmd = getaudio(input) --gets audiocmd

	local videocmd = getvideo(input, output, videoquality, filters, audiocmd) --gets videocmd

	local base = 'ffmpeg -i "' .. input .. '"' .. " -map 0:v:0" .. " -map 0:a?" .. " -map 0:s?" .. " -c:s copy" --the base of the ffmpeg command

	if filters then
		base = filters
			.. 'ffmpeg -i - -i "'
			.. input
			.. '"'
			.. " -map 0:v:0"
			.. " -map 1:a?"
			.. " -map 1:s?"
			.. " -c:s copy"
	end

	print(base .. videocmd .. audiocmd .. ' "' .. output .. '"') --prints command

	os.execute(base .. videocmd .. audiocmd .. ' "' .. output .. '"') --executes command
else
	print("you have to supply and input and output") --let user know they have to supply info to the script
end
