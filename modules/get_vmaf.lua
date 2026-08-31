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
	parallel,
	start_frame,
	end_frame,
	scene,
	previous_cq
)
	local vmaf
	local function vmaf_range(start, stop)
		local result = {}
		for v = start, stop, -1 do
			table.insert(result, v)
		end
		return result
	end
	vmaf = vmaf_range(
		98 --[[(Start)From my understanding the optimal "visually lossless" VMAF score]],
		80 --[[(Stop) just picked a low vmaf number]]
	)
	--set static variables
	local utils = pl.utils
	--set mutable variables
	local video_quality
	local current_vmaf = 0
	local current_command
	local scene_frames = {}
	local scene_number = 0
	local vmaf_to_cq = {}
	local count = 0
	local cq = 50
	local old_cq = 50
	local divisor
	if parallel then
		if previous_cq then
			old_cq = previous_cq
		end
		if scene then
			count = scene - 1
		end
	else
		scene = 1
	end
	local temporary = string.format("%s_%s_temp.mkv", output, scene)
	local reference = string.format("%s_%s_ref.mkv", temporary, scene)
	--start function
	if not parallel then
		if #scenes >= 8 then
			divisor = 8
			while count < 8 do
				local random = math.random(1, #scenes)
				if not scene_frames[random] then
					scene_frames[random] = scenes[random]
					count = count + 1
				end
			end
		else --both of these if statements just add random scenes to a table, 4 by default but in rare instances if there are less than 4 it just does them all
			divisor = #scenes
			while count < #scenes do
				local random = math.random(1, #scenes)
				if not scene_frames[random] then
					scene_frames[random] = scenes[random]
					count = count + 1
				end
			end
		end
	else
		scene_frames = { { start_frame, end_frame } }
		divisor = 1
	end
	for key, value in pairs(scene_frames) do
		pl.file.delete(reference) --delete previous reference/reference reference from failed encode
		cq = old_cq --set cq back to 50 or a safe starting point for a new scene
		scene_number = scene_number + 1
		scene = scene_number
		local vmaf_values = {}
		local scene_success
		local start_time = value[1]
		local stop_time = value[2] - 1
		local vmaf_command = string.format(
			[[ffmpeg -i "%s" -i "%s" -filter_complex "[0:v:0]scale=1920:1080[distorted];[1:v:0]scale=1920:1080[reference];[distorted][reference]libvmaf" -f null -]],
			temporary,
			reference
		)
		local reference_command = string.format(
			[[%s -an %s "%s"]],
			base(string.format(filters.proxy.ffmpeg, start_time, stop_time), input),
			ffv1_command,
			reference
		)
		count = 0
		local reference_success
		while not reference_success and count < 5 do
			print(
				string.format(
					"Encoding reference %s/%s! This part can be fast or take a while, no matter what, it speeds up the process overall.",
					scene_number,
					divisor
				)
			)
			pl.file.delete(reference)
			reference_success = utils.executeex(reference_command)
			count = count + 1
		end
		for key, target_vmaf in pairs(vmaf) do
			if not vmaf_values[1] then --checks if the vmaf_values table exists, this table is so we can encode less saving the user time and money!
				while current_vmaf < target_vmaf and cq > 2 do
					cq = cq - 2
					pl.file.delete(temporary) --delete old temp file
					local command = video_command(cq)
					local temporary_command = string.format(
						[[ffmpeg -i "%s" -map 0:v:0 -map 0:a? -map 0:s? -c:s copy -c:a copy -fflags +genpts -async 0 %s "%s"]],
						reference,
						command,
						temporary
					)
					local command_success = utils.executeex(temporary_command)
					if not command_success then
						print("encoding to av1 failed!")
					end
					local success, returncode, command_out, errout = utils.executeex(vmaf_command) --not sure why but ffmpeg puts this stuff in the err out at least on windows
					if success then
						local vmaf_string = string.match(errout, "VMAF score:%s*([%d.]+)")
						local vmaf_score = tonumber(vmaf_string)
						if vmaf_score then
							current_vmaf = vmaf_score
							vmaf_values[#vmaf_values + 1] = { vmaf_score, cq }
						end
					end
				end
			end
			for key, vmaf_value in pairs(vmaf_values) do
				if vmaf_value[1] >= target_vmaf then
					--this is such simple code that saves so much time and money, idk why but I just felt this should be pointed out, maybe because some people might not think of it
					current_vmaf = vmaf_value[1]
					cq = vmaf_value[2]
					break
				end
			end
			if current_vmaf >= target_vmaf then
				scene_success = true
				vmaf_to_cq[#vmaf_to_cq + 1] = cq
				cq = cq + 10 --add 8 but also 2 more due to how the loop works, this way we waste less time narrowing the vmaf in theory
				if cq > 50 then
					cq = 50
				end
				old_cq = cq
				current_vmaf = 0
				--if vmaf is set successfully then break the loop and set current vmaf to a better starting position to reach the vmaf faster
				break
			else
				cq = old_cq
			end
		end
		if not scene_success then --checks if a scene failed to encode and breaks
			break
		end
	end
	--delete temp files
	pl.file.delete(temporary)
	pl.file.delete(reference)
	--make sure that there are enough cq values to parse
	if #vmaf_to_cq < divisor then
		--if there's not enough cq values, it does a fallback
		print("failed to get the vmaf score, requesting from module or using fallback")
		if args.fallbackquality then
			video_quality = args.fallbackquality
		else
			video_quality = get_quality(input, ffprobe, gpu, args, pl)
		end
		return video_quality
	end
	local previous
	for key, value in pairs(vmaf_to_cq) do
		if previous then
			previous = previous + value
		else --simple code to add the values
			previous = value
		end
	end
	video_quality = previous / divisor --divide the added values by the divisor to get the mean(average) quality
	return video_quality
end
return get_vmaf
