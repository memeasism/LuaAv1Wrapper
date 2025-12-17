from vapoursynth import core

clip = core.bs.VideoSource(source = video)

clip = core.tivtc.TFM(clip, slow = ivtc_slow, order = ivtc_field_order)
clip = core.tivtc.TDecimate(clip)


clip.set_output()