from vapoursynth import core
import havsfunc
clip = core.ffms2.Source(video, fpsnum=fps_dividend, fpsden=fps_divisor)
clip = core.tivtc.TFM(clip, slow = ivtc_slow, order = ivtc_field_order)
clip = core.tivtc.TDecimate(clip)
clip = havsfunc.QTGMC(clip, Preset = deinterlace_preset, TFF = deinterlace_field_order)
clip.set_output()

