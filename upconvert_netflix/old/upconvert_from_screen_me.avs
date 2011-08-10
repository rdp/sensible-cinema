# from http://avisynth.org/mediawiki/Enhancing_dvd_videos

Video = DirectShowSource("uscreen_me.GRF", fps=24, audio=False, framecount=1000000)
Video = ConvertToYUY2 (Video)

# get these from examining the window size or through trial and error.
subject_x = 880
subject_y = 440

# these are the size of your monitor that the output is displayed on.
screen_width = 1680
screen_height = 1050

# note that you can get even better looking images by say, upscaling to 2x your screen resolution
# screen_width = screen_width*2
# screen_height = screen_height*2

Video = Lanczos4Resize (Video, screen_width, screen_height) # said to be a good upsampler...hmm...

Video = Sharpen (Video, 0.78) # Helps sharpen smoothness enlarging does. 0.78 = (1.25*(1024/720))-1
Return Video
