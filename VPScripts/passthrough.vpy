from vapoursynth import core
clip = core.ffms2.Source(video, fpsnum=fps_dividend, fpsden=fps_divisor)
clip.set_output()
