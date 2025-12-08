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
parser:flag("-l --interlaced", "your video will be deinterlaced(may not work with cpu av1)")
parser:flag("-t --telecine", "your video will be detelecined(may not work with cpu av1)")
parser:flag("-c --cpu", "encode with cpu instead of gpu") --sets the actual arguments for the script

local args = parser:parse() --parses arguments

return args
