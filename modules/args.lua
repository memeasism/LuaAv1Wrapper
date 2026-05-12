local function getargs(pl)
	local function format(file)
		if not file then
			return nil
		end
		file = string.gsub(file, '"', "")
		file = string.gsub(file, "\\$", "")
		file = string.gsub(file, "\\", "/")
		return file
	end
	pl.lapp.add_type("file-dir-in", "stdin", function(file)
		local formatted = format(file)
		local is_file = pl.path.isfile(formatted)
		local is_dir = pl.path.isdir(formatted)
		if is_file then
			return formatted
		end
		if is_dir then
			return formatted
		end
	end)

	local args = pl.lapp([[
	Encode video to AV1 Visually Losslessly
	<input> (file-dir-in) The input file or directory, must be in single quotes
	-v,--video (optional av1|ffv1) The video codec used (av1 or ffv1)
	-a,--audio (optional opus|flac) The audio codec used (opus or flac)
	-q,--videoquality (optional 0..51) The quality of the video, 0-255, the lower the higher the quality, also skips vmaf
	-f,--fallbackquality (optional 0..51) --q,--videoquality except it's used if VMAF fails
	-b,--audiobitrate (optional string) The bitrate of the audio, defined in bps, or in kbps for example: 128k for 128 kbps
	-n,--noise (optional 0..50) Value 0-50 for CPU encoder to do film grain synthesis and denoise
	-p,--progressive		Your video will be encoded as progressive
	-l,--interlaced		Your video will be deinterlaced
	-t,--telecined		Your video will be inverse telecined
	--deinterlace_bff		Your video will be deinterlaced bottom field first
	--ivtc_bff		Your video will be inverse telecined bottom field first
	-c,--cpu		Your video will be encoded on cpu
	-s,--skipvmaf		Your video will be encoded using the stored quality values instead of dynamically finding the best quality for your content type
	-m,--mass		Lets the script know that your input is a folder
	<output> (optional string) The output file or directory
	]])
	return args
end
return getargs
