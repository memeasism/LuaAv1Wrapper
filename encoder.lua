local lfs = require("lfs")
local pl = require("pl.import_into")()
print(package.cpath)
local args = require("modules/args") --gets arguments
local getfilters = require("modules/getfilters") --sets function modules
local getquality = require("modules/getquality")
local getaudio = require("modules/getaudio")
local getfps = require("modules/getfps")
local getvideo = require("modules/getvideo")
local getfields = require("modules/getfields")
local extentions = require("modules/extentions")
local getsize = require("modules/getsize")
local getffprobe = require("modules/ffprobe")
local getgpu = require("modules/getgpu")
local input = {}
local output = {}
if not (args.input and args.output) then
	print("you have to supply and input and output") --let user know they have to supply info to the script
	pl.utils.quit()
end
if args.mass then
	local temp_output = lfs.mkdir(args.output)
	if output then
		temp_output = lfs.currentdir() .. "/" .. args.output
	end
	local dir = lfs.chdir(args.input)
	if not dir then
		print("Input Directory Doesn't Exist")
		pl.utils.quit()
	end
	local dir = lfs.currentdir()
	for file in lfs.dir(lfs.currentdir()) do
		for key, value in pairs(extentions) do
			if string.match(file, "." .. "." .. value) then
				table.insert(input, dir .. "/" .. file)
				table.insert(output, temp_output .. "/" .. file)
			end
		end
	end
else
	table.insert(input, lfs.currentdir() .. "/" .. args.input) --sets input as the full path to fix any errors vspipe may have
	table.insert(output, lfs.currentdir() .. "/" .. args.output) --sets output
end
for key, value in pairs(input) do
	local gpu = getgpu(args)
	local ffprobe = getffprobe(value)
	local content = getfields(value)
	local fpstable = getfps(ffprobe)
	local filters = getfilters(value, content, fpstable, args, pl) --gets filters
	local videoquality = getquality(value, ffprobe, gpu, args) --gets quality
	local audiocmd = getaudio(value, ffprobe, args) --gets audiocmd
	local aspect = getsize(value, ffprobe)
	local videocmd = getvideo(value, output, videoquality, fpstable, filters, audiocmd, ffprobe, gpu, aspect, args, pl) --gets videocmd
	local base = 'ffmpeg -i "'
		.. value
		.. '"'
		.. [[ -filter_complex "[0:v]setdar=]]
		.. aspect
		.. '"'
		.. " -map 0:v:0"
		.. " -map 0:a?"
		.. " -map 0:s?"
		.. " -c:s copy"
		.. " -fflags +genpts"
		.. " -async 0" --the base of the ffmpeg command
	if filters then
		base = filters.ffmpeg
			.. 'ffmpeg -i - -i "'
			.. value
			.. '"'
			.. [[ -filter_complex "[0:v]setdar=]]
			.. aspect
			.. [["]]
			.. " -map 0:v:0"
			.. " -map 1:a?"
			.. " -map 1:s?"
			.. " -c:s copy"
			.. " -fflags +genpts"
			.. " -async 0"
	end
	print("Executing: " .. base .. videocmd .. audiocmd .. ' "' .. output[key] .. '"') --prints command
	os.execute(base .. videocmd .. audiocmd .. ' "' .. output[key] .. '"') --executes command
end
