local lfs = require("lfs")

local args = require("modules/args") --gets arguments

local getfilters = require("modules/getfilters") --sets function modules

local getquality = require("modules/getquality")

local getaudio = require("modules/getaudio")

local getvideo = require("modules/getvideo")

local extentions = require("modules/extentions")

local input = {}

local output = {}

if args.input and args.output ~= nil then
	if args.mass then
		local temp_output = lfs.mkdir(args.output)
		if output then
			temp_output = lfs.currentdir() .. "/" .. args.output
		end
		local dir = lfs.chdir(args.input)
		if dir then
			local dir = lfs.currentdir()
			for file in lfs.dir(lfs.currentdir()) do
				for key, value in pairs(extentions) do
					if string.match(file, "." .. "." .. value) then
						table.insert(input, dir .. "/" .. file)
						table.insert(output, temp_output .. "/" .. file)
					end
				end
			end
		end
	else
		table.insert(input, lfs.currentdir() .. "/" .. args.input) --sets input as the full path to fix any errors vspipe may have

		table.insert(output, lfs.currentdir() .. "/" .. args.output) --sets output
	end

	for key, value in pairs(input) do
		local filters = getfilters(value) --gets filters

		local videoquality = getquality(value) --gets quality

		local audiocmd = getaudio(value) --gets audiocmd

		local videocmd = getvideo(value, output, videoquality, filters, audiocmd) --gets videocmd

		local base = 'ffmpeg -i "' .. value .. '"' .. " -map 0:v:0" .. " -map 0:a?" .. " -map 0:s?" .. " -c:s copy" --the base of the ffmpeg command

		if filters then
			base = filters
				.. 'ffmpeg -i - -i "'
				.. value
				.. '"'
				.. " -map 0:v:0"
				.. " -map 1:a?"
				.. " -map 1:s?"
				.. " -c:s copy"
		end

		print(base .. videocmd .. audiocmd .. ' "' .. output[key] .. '"') --prints command

		os.execute(base .. videocmd .. audiocmd .. ' "' .. output[key] .. '"') --executes command
	end
else
	print("you have to supply and input and output") --let user know they have to supply info to the script
end
