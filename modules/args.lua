local argparse = require("argparse") --load argparse module
local parser = argparse():name("encoder"):description("an open source encoding script"):epilog(
	"All of these are optional except for -i and -o as this script is designed to find the best audio codec and bitrate by using ffprobe and also detects user gpu"
) --sets script arguments
parser:option():name("-i --input")
parser:option():name("-o --output")
parser:option():name("-v --video"):choices({ "av1", "ffv1" })
parser:option():name("-a --audio"):choices({ "opus", "flac" })
parser:option():name("-q --videoquality"):description("cqp value 0-255, lower is higher quality but larger files")
parser:option():name("-b --audiobitrate"):description("actual audio bitrate in bits or for kbps as such: 128k")
parser:option():name("-n --noise"):description("CPU ONLY! value 0-50 0=off will denoise and do grain synthesis")
parser:flag("-p --progressive", "your video will be marked as progressive")
parser:flag("-l --interlaced", "your video will be deinterlaced.")
parser:flag("--deinterlace_bff", "Default for interlacing is top field first, so use this for bottom field first")
parser:flag("-t --telecine", "your video will be detelecined.")
parser:flag("--ivtc_bff", "Default for inverse telecine is top field first, so use this for bottom field first")
parser:flag("-m --mass", "encode an entire directory instead of just one file at a time")
parser:flag("-c --cpu", "encode with cpu instead of gpu") --sets the actual arguments for the script
local args = parser:parse() --parses arguments
return args
