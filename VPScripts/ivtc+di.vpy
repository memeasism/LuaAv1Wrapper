from vapoursynth import core
from vsdeinterlace import QTempGaussMC as QTGMC
clip = core.ffms2.Source(video, fpsnum=fps_dividend, fpsden=fps_divisor)
clip = core.tivtc.TFM(clip, slow = ivtc_slow, order = ivtc_field_order)
clip = core.tivtc.TDecimate(clip)
tff_value = deinterlace_bff == "True"
clip = QTGMC(clip, Preset=deinterlace_preset , opencl=True, TFF=tff_value)
clip.set_output()

