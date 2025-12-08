local args = require("args") --gets arguments

local gpu --sets variable before checking

if args.cpu then --checks if user used -c flag for cpu
	gpu = 0
end

local gpuparse

local windows

if os.getenv("OS") then
	windows = true
else
	windows = false
end --checks if user is on windows or not so it can use windows or unix commands to detect gpu

if gpu ~= 0 then
	if windows == true then
		gpu = io.popen(
			'powershell -Command "Get-CimInstance -ClassName Win32_VideoController | Select-Object -ExpandProperty Name"'
		)
	else
		gpu = io.popen("lspci | grep -i vga")
	end --runs windows or unix command to get gpu

	gpuparse = gpu:read("*a")

	if gpu ~= 0 then
		if string.find(gpuparse, "Intel") then
			print("is Intel")

			gpu = 1
		elseif string.find(gpuparse, "AMD") then
			print("is AMD")

			gpu = 2
		elseif string.find(gpuparse, "NVIDIA") then
			print("is NVIDIA")

			gpu = 3
		else
			print("using CPU")

			gpu = 0
		end
	end --checks what GPU the user has and provides feedback and then sets variable
end

return gpu
