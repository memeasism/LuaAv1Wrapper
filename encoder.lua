local pl = require("pl.import_into")()
local args = require("modules/args")(pl) --gets arguments
local cjson = require("cjson")
local getfilters = require("modules/getfilters") --sets function modules
local getquality = require("modules/getquality")
local getaudio = require("modules/getaudio")
local getfps = require("modules/getfps")
local getvideo = require("modules/getvideo")
local getfields = require("modules/getfields")
local extentions = require("modules/extentions")
local no_flac_extensions = extentions.no_flac_extensions
extentions = extentions.exensions
local getsize = require("modules/getsize")
local getffprobe = require("modules/ffprobe")
local getgpu = require("modules/getgpu")
local getvmaf = require("modules/getvmaf")
local output_format = ".webm" --Amazing open standard that supports opus better than mkv
if args.video == "ffv1" then
	output_format = ".mkv"
end
local video = pl.path.normpath(args.input)
local out = args.output
local input = {}
local output = {}
if not out then
	out = "av1_out"
end
if not video then
	print("you have to supply an input") --let user know they have to supply info to the script
	pl.utils.quit()
end
if args.mass or pl.path.isdir(video) then
	local folder = pl.path.abspath(video)
	local output_folder = pl.path.join(folder, out)
	if not pl.path.isdir(folder) then
		print("Input Directory Doesn't Exist")
		pl.utils.quit()
	end
	pl.path.mkdir(output_folder)
	for file in pl.path.dir(folder) do
		local input_format = pl.path.extension(file)
		for key, ext in pairs(extentions) do
			if string.match(input_format, ext) then
				local input_string = pl.path.join(folder, file)
				local output_name = string.gsub(file, input_format, output_format)
				local output_string = pl.path.join(output_folder, output_name)
				if not pl.path.isfile(output_string) then
					table.insert(input, input_string)
					table.insert(output, output_string)
				else
					print(string.format([[Output file "%s" exists, skipping]], output_string))
				end
			end
		end
	end
else
	local currentdir = pl.path.currentdir()
	local input_string = pl.path.abspath(video)
	local input_alone = string.gsub(pl.path.basename(video), pl.path.extension(video), "")
	local output_string
	local fallback_string = pl.path.join(currentdir, string.format([[%s%s%s]], input_alone, out, output_format))
	if not (pl.path.isfile(fallback_string) or pl.path.isfile(out)) then
		for key, ext in pairs(extentions) do
			if string.match(video, ext) then
				for key, ext2 in pairs(extentions) do
					if string.match(out, ext2) then
						table.insert(input, input_string)
						table.insert(output, pl.path.abspath(out))
						output_string = out
						break
					end
				end
				break
			end
		end
		if not output_string then
			output_string = fallback_string
			table.insert(input, input_string)
			table.insert(output, fallback_string)
		end
	else
		print(string.format([[Output file "%s" exists, skipping!]], out))
	end
end
for key, file in pairs(input) do
	local ffprobe = getffprobe(file, pl, cjson)
	if not ffprobe then
		print(string.format("Not a valid input file: %s, skipping.", file))
	elseif ffprobe.video.streams[1] then
		--pl.pretty.dump(ffprobe.video.streams[1])
		--pl.utils.quit()
		local audiocmd, output = getaudio(file, output[1], no_flac_extensions, ffprobe, args, pl) --gets audiocmd
		if not pl.path.isfile(output) then
			local gpu = getgpu(args, pl)
			local content = getfields(file, args, pl)
			local fpstable = getfps(ffprobe, pl)
			local filters = getfilters(file, content, fpstable, args, pl) --gets filters
			local aspect = getsize(file, ffprobe, pl)
			local videocmd = getvideo(
				file,
				output,
				getquality,
				fpstable,
				content,
				filters,
				audiocmd,
				ffprobe,
				gpu,
				aspect,
				getvmaf,
				args,
				pl,
				cjson
			) --gets videocmd
			if videocmd ~= "skip" then
				print("Executing: " .. videocmd) --prints command
				pl.utils.execute(videocmd) --executes command
			end
		else
			print(
				string.format(
					[[Output file "%s" exists, skipping!
If this output file doesn't match what your original input was, it's because the audio is flac and flac doesn't work in webm.]],
					output
				)
			)
		end
	end
end
