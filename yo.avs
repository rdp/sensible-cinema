# from http://avisynth.org/mediawiki/Enhancing_dvd_videos

Video = DirectShowSource("uscreen.GRF", fps=30, audio=False, framecount=1000000)
Video = ConvertToYUY2 (Video)
Video = LanczosResize (Video, 1680, Video.Height) # Uses the most effective resizer to span the video out.
Video = Sharpen (Video, 0.78) # Helps sharpen smoothness enlarging does. 0.78 = (1.25*(1024/720))-1
Return Video
