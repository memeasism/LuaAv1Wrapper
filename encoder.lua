--define all modules
local pl = require("pl.import_into")()
local args = require("modules/args")(pl) --gets arguments
local cjson = require("cjson")
local extentions = require("modules/extentions")
local get_audio = require("modules/get_audio")
local get_ffprobe = require("modules/ffprobe")
local get_fields = require("modules/get_fields")
local get_filters = require("modules/get_filters")
local get_fps = require("modules/get_fps")
local get_gpu = require("modules/get_gpu")
local get_quality = require("modules/get_quality")
local get_size = require("modules/get_size")
local get_video = require("modules/get_video")
local no_flac_extensions = extentions.no_flac_extensions
local no_subtitle_extensions = extentions.no_subtitle_extensions
--set input and output info
local input = {}
local output = {}
local video = pl.path.abspath(args.input)
local output_file = args.output
--define static variables
local path = pl.path
local abspath = path.abspath
local audio = args.audio
local codec = args.video
local join = path.join
local mass = args.mass
local mkv = args.mkv
local output_format = ".webm"
local output_placeholder = "av1_out"
local utils = pl.utils
--redefine variables if necessary
extentions = extentions.exensions
if codec == "ffv1" or audio == "flac" or mkv then
	output_format = ".mkv" --if the user sets video codec to ffv1 or audio to flac then change output to mkv, also if the mkv flag is used obviously
end
if not video then
	print("you have to supply an input") --let user know they have to supply info to the script
	utils.quit()
end
if mass or path.isdir(video) then
	--define statements variables
	local output_folder
	--execute
	if output_file then
		output_folder = abspath(output_file)
	else
		output_folder = join(video, output_placeholder)
	end
	path.mkdir(output_folder)
	for file in path.dir(video) do
		--define loops variables
		local input_format = path.extension(file)
		--run loop
		for key, ext in pairs(extentions) do
			if string.match(input_format, ext) then
				--define statements variables
				local input_string = join(video, file)
				local output_name = string.gsub(file, input_format, output_format)
				local output_string = join(output_folder, output_name)
				--execute
				if not path.isfile(output_string) then --check to make sure output doesn't exist
					table.insert(input, input_string)
					table.insert(output, output_string)
				else
					print(string.format([[Output file "%s" exists, skipping]], output_string))
				end
			end
		end
	end
else
	--define statements variables
	local currentdir = path.currentdir()
	local input_alone = string.gsub(path.basename(video), path.extension(video), "")
	local input_string = abspath(video)
	if not output_file then
		output_file = output_placeholder
	end
	local fallback_string = join(currentdir, string.format([[%s_%s%s]], input_alone, output_file, output_format))
	local output_string
	if not (path.isfile(fallback_string) or path.isfile(output_file)) then --make sure that the output doesn't exist
		for key, ext in pairs(extentions) do
			--iterate over the file extentions table and check for a match
			if string.match(video, ext) then
				--if the input video matches a supported extention, check that the output file has a supported extention
				for key, ext2 in pairs(extentions) do
					if string.match(output_file, ext2) then
						--add input and output files to their respective tables
						table.insert(input, input_string)
						table.insert(output, abspath(output_file))
						output_string = output_file
						break
					end
				end
				break
			end
		end
		if not output_string then
			--sets output to be a backup command
			output_string = fallback_string
			table.insert(input, input_string)
			table.insert(output, fallback_string)
		end
	else
		--let the user know there's an issue if the files exist
		print(string.format([[Output file "%s" exists, skipping!]], output_file))
	end
end
for key, file in pairs(input) do --repeats these functions for all input files
	local ffprobe = get_ffprobe(file, pl, cjson) --gets ffprobe info for encoding, and also verifies input is a real video file
	if not ffprobe then
		--if ffprobe fails tell the user
		print(string.format("Not a valid input file: %s, skipping.", file))
	elseif ffprobe.video.streams[1] then --if there is a video stream then run the next commands
		local audio_command, output = get_audio(file, output[key], no_flac_extensions, ffprobe, args, pl)
		--gets the audio command and also redefines our output file because webm, the default container doesn't support webm so, it corrects itself
		if not path.isfile(output) then --check if output file exists again
			local gpu = get_gpu(args, pl) --detect the gpu that the user has
			local content = get_fields(file, args) --detect the content type of video, like progressive or interlaced
			local fps_table = get_fps(ffprobe) --returns source videos fps
			local filters = get_filters(file, content, fps_table, args, pl) --gets filters based off content type
			local aspect = get_size(file, ffprobe) --gets the aspect ratio for the video
			local video_command = get_video(
				args,
				aspect,
				audio_command,
				cjson,
				content,
				ffprobe,
				file,
				filters,
				fps_table,
				get_quality,
				gpu,
				no_subtitle_extensions,
				output,
				pl
			) -- gets the encoder command
			if video_command ~= "skip" then
				print("Executing: " .. video_command) --prints command
				utils.execute(video_command) --executes command
			end
		else
			--provides user input that once again the output file exists
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
