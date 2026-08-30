#inport the stuff
from vapoursynth import core
#do the stuff
clip = core.ffms2.Source(video, fpsnum=fps_dividend, fpsden=fps_divisor)
if DI_value == b'True':
    clip = core.std.SetFieldBased(clip, 2)
else:
    clip = core.std.SetFieldBased(clip, 1)
if DI_value == True:
    field_order = 1
else:
    field_order = 0
#clip = BWDIF(tff=DI_value, double_rate=True).bob(clip)
core.yadifmod.Yadifmod(clip, order=field_order, mode=1, opt=0)
#output
clip.set_output()