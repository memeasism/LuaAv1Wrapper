#inport the stuff
from vapoursynth import core
from vsaa import Deinterlacer as Deinterlacer
#do the stuff
clip = core.ffms2.Source(video, fpsnum=fps_dividend, fpsden=fps_divisor)
if DI_value == b'True':
    clip = core.std.SetFieldBased(clip, 2)
else:
    clip = core.std.SetFieldBased(clip, 1)
clip = Deinterlacer(tff=DI_value, double_rate=True).bob(clip)
#output
clip.set_output()