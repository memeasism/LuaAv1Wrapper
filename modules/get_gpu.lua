local function getgpu(args, pl)
	local gpu --sets variable before checking
	if args.cpu then --checks if user used -c flag for cpu
		gpu = 0
	end
	local windows = pl.path.is_windows --checks if user is on windows or not so it can use windows or unix commands to detect gpu
	if gpu ~= 0 then
		if windows == true then
			local sucess, gpu_return, graphics, err = pl.utils.executeex(
				'powershell -Command "Get-CimInstance -ClassName Win32_VideoController | Select-Object -ExpandProperty Name"'
			)
			if not sucess then
				gpu = 0
				return gpu
			end
			gpu = graphics
		else
			local sucess, gpu_return, graphics, err = pl.utils.executeex("lspci | grep -i vga")
			if not sucess then
				gpu = 0
				return gpu
			end
			gpu = graphics
		end --runs windows or unix command to get gpu
		if gpu ~= 0 then
			if string.find(gpu, "Intel") then
				gpu = 1
			elseif string.find(gpu, "AMD") then
				gpu = 2
			elseif string.find(gpu, "NVIDIA") then
				gpu = 3
			else
				gpu = 0
			end
		end --checks what GPU the user has and provides feedback and then sets variable
	end
	return gpu
end
return getgpu
