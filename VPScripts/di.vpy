#import the stuff
from vapoursynth import core
from vsdeinterlace import QTempGaussMC as QTGMC
#do the stuff
clip = core.ffms2.Source(video, fpsnum=fps_dividend, fpsden=fps_divisor)
clip = QTGMC(clip, DI_value, QTGMC.InputType.INTERLACE).deinterlace()
#output
clip.set_output()

