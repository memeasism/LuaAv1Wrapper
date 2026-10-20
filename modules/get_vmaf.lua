local function get_vmaf(
	input,
	ffprobe,
	gpu,
	args,
	output,
	video_command,
	get_quality,
	pl,
	base,
	ffv1_command,
	filters,
	scenes,
	start_frame,
	end_frame,
	scene,
	previous_cq,
	pre_roll
)
	local vmaf_filters = "scale=-2:1080:flags=lanczos"
	local vmaf_model = "vmaf_v0.6.1"
	if tonumber(ffprobe.video.streams[1].height) then
		if tonumber(ffprobe.video.streams[1].height) >= 2160 then
			vmaf_model = "vmaf_4k_v0.6.1"
			vmaf_filters = "scale=-2:2160:flags=lanczos"
		end
	end
	local target_vmaf = args.vmaf or 98
	local fallback_vmaf = args.fallbackvmaf or 80
	local vmaf
	local function vmaf_range(start, stop)
		local result = {}
		for v = start, stop, -1 do
			table.insert(result, v)
		end
		return result
	end
	vmaf = vmaf_range(
		target_vmaf, --[[(Start)From my testing the optimal "visually lossless" VMAF score]]
		fallback_vmaf --[[(Stop) just picked a low vmaf number]]
	)
	--set static variables
	local utils = pl.utils
	--set mutable variables
	local video_quality
	local current_vmaf = 0
	local current_command
	local scene_frames = {}
	local limit = 51
	local old_cq = limit
	local ceiling = old_cq
	local floor = 2
	local break_loop
	if previous_cq then
		old_cq = math.min(((previous_cq + 6) - (floor / 2)), (limit - (floor / 2))) * 2
	end
	local cq = 36
	local divisor
	local temporary = string.format("%s_%s_temp.mkv", output, scene)
	local reference = string.format("%s_%s_ref.mkv", temporary, scene)
	--start function
	scene_frames = { { start_frame, end_frame } }
	divisor = 1
	for key, value in pairs(scene_frames) do
		local vmaf_values = {}
		pl.file.delete(reference) --delete previous reference/reference reference from failed encode
		cq = old_cq + 8 --set cq back to 50 or a safe starting point for a new scene
		local start_time = value[1]
		local stop_time = value[2] - 1
		local vmaf_command = string.format(
			[[ffmpeg -i "%s" -i "%s" -filter_complex "[0:v]%s[distorted];[1:v]%s[refrence];[distorted][refrence]libvmaf=model=version=%s:n_threads=2:n_subsample=2" -f null -]],
			temporary,
			reference,
			vmaf_filters,
			vmaf_filters,
			vmaf_model
		)
		local reference_command = string.format(
			[[%s -an -sn %s "%s"]],
			base(string.format(filters.proxy.ffmpeg, start_time, stop_time), input, pre_roll),
			ffv1_command,
			reference
		)
		for i = 1, 5 do
			local reference_success = utils.executeex(reference_command)
			if reference_success then
				break
			end
			pl.file.delete(reference)
			if i == 5 then
				print("Failed to encode refrence, skipping")
				return "error"
			end
		end
		while ceiling >= floor do
			cq = math.floor((floor + ceiling) / 2)
			pl.file.delete(temporary) --delete old temp file
			local command = video_command(cq, args, 0)
			local temporary_command =
				string.format([[ffmpeg -i "%s" -map 0:v:0 %s "%s"]], reference, command, temporary)
			for i = 1, 5 do
				local command_success = utils.executeex(temporary_command)
				if command_success then
					break
				end
				if i == 5 then
					print("Failed to encode temporary file, skipping")
					return "error"
				end
			end
			for i = 1, 5 do
				local success, returncode, command_out, errout = utils.executeex(vmaf_command) --not sure why but ffmpeg puts this stuff in the err out at least on windows
				if success then
					local vmaf_string = string.match(errout, "VMAF score:%s*([%d.]+)")
					local vmaf_score = tonumber(vmaf_string)

					if vmaf_score then
						current_vmaf = vmaf_score
						table.insert(vmaf_values, { vmaf_score, cq })
						if current_vmaf >= target_vmaf then
							local difference = current_vmaf - target_vmaf
							video_quality = cq
							if difference <= 1 then
								break_loop = true
								break
							end
							floor = cq + 1
						else
							ceiling = cq - 1
						end
						if ceiling > limit then
							ceiling = limit
						end
					else
						print("Failed to parse a VMAF Score! Skipping!")
						return "error"
					end
				end
			end
			if break_loop then
				break
			end
		end
		if not video_quality then
			for vmaf_key = #vmaf_values, 1, -1 do
				if video_quality then
					break
				end
				local vmaf_value = vmaf_values[vmaf_key]
				for key, current_target_vmaf in ipairs(vmaf) do
					if vmaf_value[1] >= current_target_vmaf then
						--this is such simple code that saves so much time and money, idk why but I just felt this should be pointed out, maybe because some people might not think of it
						current_vmaf = vmaf_value[1]
						video_quality = vmaf_value[2]
						break
					end
				end
			end
		end
	end
	--delete temp files
	pl.file.delete(temporary)
	pl.file.delete(reference)
	--make sure that there are enough cq values to parse
	if not video_quality then
		--if there's not enough cq values, it does a fallback
		print("failed to get the vmaf score, requesting from module or using fallback")
		if args.fallbackquality then
			video_quality = args.fallbackquality
		else
			video_quality = get_quality(input, ffprobe, gpu, args, pl)
		end
	else
		video_quality = video_quality
	end
	return video_quality
end
return get_vmaf
