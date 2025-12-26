from vapoursynth import core
from vsdeinterlace import QTempGaussMC as QTGMC
clip = core.ffms2.Source(video, fpsnum=fps_dividend, fpsden=fps_divisor)
clip = core.tivtc.TFM(clip, slow = ivtc_slow, order = ivtc_field_order)
clip = core.tivtc.TDecimate(clip)
props = clip.get_frame(0).props
is_interlaced = props.get('_FieldBased', 0) != 0
if is_interlaced:
  clip = QTGMC(clip, QTGMC.InputType.INTERLACE).deinterlace
else:
  clip = QTGMC(clip, QTGMC.InputType.PROGRESSIVE).deinterlace()
clip.set_output()

