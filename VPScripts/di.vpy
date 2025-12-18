from vapoursynth import core
import havsfunc

clip = core.ffms2.Source(video)

fps = clip.

clip = havsfunc.QTGMC(clip, Preset = deinterlace_preset, TFF = deinterlace_field_order)

clip.set_output()