
#import the stuff
from vapoursynth import core
from vsdeinterlace import vfm
from vsdeinterlace import vdecimate
from vsdeinterlace import FixInterlacedFades
from vsdeinterlace import vinverse
from vsdeinterlace import QTempGaussMC as QTGMC
from vsaa import NNEDI3
#do the stuff
clip = core.ffms2.Source(video, fpsnum=fps_dividend, fpsden=fps_divisor)
clip = vfm(clip, IVTC_value)
clip = FixInterlacedFades.MATCH(clip)
cpip = vinverse(clip)
clip = vdecimate(clip)
if DI_value == b'True':
    clip = core.std.SetFieldBased(clip, 2)
else:
    clip = core.std.SetFieldBased(clip, 1)
clip = QTGMC(clip, DI_value, QTGMC.InputType.REPAIR).lossless().basic(bobber=NNEDI3(opencl=True)).deinterlace()
clip = clip[::2]
#output
clip.set_output(0)
clip.set_output(1)