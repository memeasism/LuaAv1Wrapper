from vapoursynth import core

clip = core.ffms2.Source(video)

clip = core.tivtc.TFM(clip, slow = ivtc_slow, order = ivtc_field_order)

clip = core.tivtc.TDecimate(clip)

clip.set_output()