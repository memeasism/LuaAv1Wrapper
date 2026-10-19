local function getgpu(args, pl)
	local gpu --sets variable before checking
	local windows_command =
		'powershell -Command "Get-CimInstance -ClassName Win32_VideoController | Select-Object -ExpandProperty Name"'
	local linux_command = "lspci | grep -i vga"
	if args.cpu then --checks if user used -c flag for cpu
		gpu = 0
	end
	local windows = pl.path.is_windows --checks if user is on windows or not so it can use windows or unix commands to detect gpu
	if gpu ~= 0 then
		if windows == true then
			for i = 1, 5 do
				local sucess, gpu_return, graphics, err = pl.utils.executeex(windows_command)
				if sucess then
					gpu = graphics
					break
				end
				if i == 5 then
					gpu = 0
					return gpu
				end
			end
		else
			for i = 1, 5 do
				local sucess, gpu_return, graphics, err = pl.utils.executeex(linux_command)
				if sucess then
					gpu = graphics
					break
				end
				if i == 5 then
					gpu = 0
					return gpu
				end
			end
		end
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
	return gpu
end
return getgpu
