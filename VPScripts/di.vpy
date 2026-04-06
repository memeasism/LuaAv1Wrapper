from vapoursynth import core
from qtgmc import QTGMC
clip = core.ffms2.Source(video, fpsnum=fps_dividend, fpsden=fps_divisor)
tff_value = deinterlace_bff == "True"
clip = QTGMC(clip, Preset=deinterlace_preset , opencl=True, TFF=tff_value)

clip.set_output()
