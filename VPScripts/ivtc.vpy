#import the stuff
from vapoursynth import core
from vsdeinterlace import vfm
from vsdeinterlace import vdecimate
from vsdeinterlace import FixInterlacedFades
from vsdeinterlace import vinverse
#do the stuff
clip = core.ffms2.Source(video, fpsnum=fps_dividend, fpsden=fps_divisor)
clip = vfm(clip, IVTC_value)
clip = FixInterlacedFades.MATCH(clip)
cpip = vinverse(clip)
clip = vdecimate(clip)
#output
clip.set_output()