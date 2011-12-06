# from http://avisynth.org/mediawiki/Enhancing_dvd_videos

Video = DirectShowSource("uscreen.GRF", fps=30, audio=False, framecount=1000000)
Video = ConvertToYUY2 (Video)

# get these from examining the window size or through trial and error.
subject_x = 720 # CHANGE THIS
subject_y = 480 # CHANGE THIS

# these are the size of your monitor that the output is displayed on.  Unless it lags too much, then try experimenting with smaller values
screen_width = 1024 # CHANGE THIS
screen_height = 768 # CHANGE THIS

# note that you can get even better looking images by say, upscaling to 2x your current screen resolution, by uncommenting the following two lines
screen_width = screen_width*2
screen_height = screen_height*2

Video = Lanczos4Resize (Video, screen_width, screen_height) # said to be a good upsampler...hmm...

Video = Sharpen (Video, 0.78) # Helps sharpen smoothness enlarging does. 0.78 = (1.25*(1024/720))-1
Return Video
