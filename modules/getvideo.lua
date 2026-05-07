local function getvideo(input, output, videoquality, fpstable, filters, audiocmd, ffprobe, gpu, aspect, args, pl)
	local videocodec --prepares the videocodec
	if args.video then
		videocodec = args.video
	else
		videocodec = "av1"
	end --checks if user set the video argument
	local videocmd --prepares the videocmd
	local noise = 0 --prepares the denoise level
	local remuxcmd
	if args.noise ~= nil then
		noise = args.noise
	end --sets noise to be what the user set
	local ffv1cmd = " -c:v ffv1" .. " -level 3" .. " -g 1" .. " -pix_fmt yuv420p10le"
	local function remux(out, file)
		local command
		command = "ffmpeg -i "
			.. pl.utils.quote_arg(file)
			.. " -i "
			.. pl.utils.quote_arg(input)
			.. " -map 0:v:0"
			.. " -map 1:a?"
			.. " -map 1:s?"
			.. " -c:v copy"
			.. " -aspect "
			.. string.gsub(aspect, "/", ":")
			.. " -metadata:s:v dispaly_aspect_ratio="
			.. aspect
			.. " -c:s copy"
			.. " -fflags +genpts"
			.. " -async 0"
			.. audiocmd
			.. " "
			.. pl.utils.quote_arg(out)
		return command
	end
	local function cpucmd(out)
		local command
		command = "av1an -i " --av1an is only for constant frame rate, the good news is that my script saves all videos as constant frame rate, you may have to run with ffv1 before using av1 though.
			.. filters.av1an
			.. " --proxy "
			.. filters.proxy
			.. " -o "
			.. pl.utils.quote_arg(out)
			.. " --temp tmp"
			.. ' -e "aom"'
			.. " --pix-format yuv420p10le"
			.. " --target-metric vmaf --target-quality 98"
			.. " -v "
			.. pl.utils.quote_arg(" --denoise-noise-level=" .. noise)
		return command
	end
	local function intelcmd(quality)
		local string = " -c:v av1_qsv"
			.. " -q:v "
			.. quality
			.. " -preset veryslow"
			.. " -extbrc 1"
			.. " -look_ahead 1"
			.. " -look_ahead_depth 60"
			.. " -look_ahead_downsampling off"
			.. " -refs 16"
			.. " -adaptive_i 1"
			.. " -adaptive_b 1"
			.. " -low_power 0"
			.. " -pix_fmt p010le"
			.. " -vtag av01"
		return string
	end
	--these set the commands for encoding
	if videocodec == "av1" then
		if gpu == 0 then
			for key, value in pairs(output) do
				local file = value .. "_temp.mkv"
				videocmd = cpucmd(file)
				remuxcmd = remux(value, file)
				print(videocmd)
				os.execute(videocmd)
				if not pl.file.read(file) then
					print("Intermediary file not found!")
					pl.utils.quit()
				end
				print("Encoding audio and copying subtitles to the output file")
				print(remuxcmd)
				os.execute(remuxcmd)
				if not pl.file.read(value) then
					print("Video failed to be remuxed")
					pl.utils.quit()
				end
				print("Remux success! Removing the intermediary video file")
				pl.file.delete(file)
			end
			pl.utils.quit()
		elseif gpu == 1 then
			videocmd = intelcmd(videoquality)
			--[[elseif gpu == 2 then
			videocmd = amdcmd
		elseif gpu == 3 then
			videocmd = nvidiacmd]]
		end
	elseif videocodec == "ffv1" then
		videocmd = ffv1cmd
	end --sets and runs encoding commands
	if not videocmd then
		print("Failed to get video command")
		return "error"
	end
	return videocmd
end
return getvideo
