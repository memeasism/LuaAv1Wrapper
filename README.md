<html>
<h1>
LuaAv1Wrapper
</h1>
<p>
A lua script that is a basic wrapper for ffmpeg and is designed to just be an easy way to encode videos visually losslessly to an open source format.

Automatically detects the optimal quality for a video via VMAF, by default it starts at vmaf 97 and goes down to 80, so although advertised as visually lossless, it's not 100% true, just the best possible quality.

The modules/getquality file includes tables of values that the output will use as a fallback if attempting to get the best possible vmaf fails, these values are based off of encoding the Beauty and Jockey videos from https://github.com/ultravideo/UVG-4K-Dataset to a VMAF of 98 or the highest possible VMAF that's under it, non floating point, so if 98 fails, we try for 97.
</p>
<h3>
Current Support
</h3>
<p>
Currently, this script only supports Intel GPU and CPU encoding.
</p>
<h3>
Dependencies
</h3>
<a href='https://raw.githubusercontent.com/memeasism/LuaAv1Wrapper/refs/heads/main/dependencies.txt' target='_blank'>
Click me to see dependencies!
</a>
<h3>
Roadmap
</h3>
<p>
<ul>
<li>
Cleaning up code and optimizations
</li>
<li>
AMD and NVIDIA support.
</li>
<li>
Grain synthesis on gpu encode(will have to make my own program to do this)
</li>
<ul>
</p>
</html>
