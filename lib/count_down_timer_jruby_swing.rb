require 'rubygems'
require 'sane' # require_relative
require_relative 'jruby-swing-helpers/swing_helpers'
require_relative 'jruby-swing-helpers/play_mp3_audio'
require_relative 'jruby-swing-helpers/storage'

include SwingHelpers
  
class MainWindow < JFrame

  def set_normal_size
      set_size 200,80
  end
  
  def super_size
    set_size 1650,1000
    self.always_on_top=true
  end

  def initialize
      super "welcome..."
      set_normal_size
	  set_location 100,100
      com.sun.awt.AWTUtilities.setWindowOpacity(self, 0.8) 
      @time_remaining_label = JLabel.new 'Welcome...'
      happy = Font.new("Tahoma", Font::PLAIN, 11)
      @time_remaining_label.set_bounds(44,44,160,14)
      @time_remaining_label.font = happy
      @name_label = JLabel.new
      @name_label.font = happy
      @name_label.set_bounds(44,4,1600,14)
      
      panel = JPanel.new
      @panel = panel
      panel.set_layout nil
      add panel # why can't I just slap these down?
      panel.add @time_remaining_label
      panel.add @name_label
      @start_time = Time.now
      cur_index = 0
      starting_seconds_requested = ARGV.map{|a| a.to_f*60}
      setup_pomo_name starting_seconds_requested[0]/60
      @switch_image_timer = javax.swing.Timer.new(1000, nil) # nil means it has no default person to call when the action has occurred...
      @switch_image_timer.add_action_listener do |e|
        seconds_requested = starting_seconds_requested[cur_index % starting_seconds_requested.length]
        next_up = starting_seconds_requested[(cur_index+1) % starting_seconds_requested.length]
        seconds_left = (seconds_requested - (Time.now - @start_time)).to_i
        if seconds_left < 0
          setState ( java.awt.Frame::NORMAL )
          setVisible(true)
          toFront()
          super_size
          set_title 'done!'
		  a = PlayMp3Audio.new('diesel.mp3')
		  a.start
          SwingHelpers.show_blocking_message_dialog "Timer done! #{seconds_requested/60}m at #{Time.now}. Next up #{next_up/60}m." 
		  a.stop
		  minutes = next_up/60
          setup_pomo_name minutes
		  if(minutes > Storage['break_time'])
            set_normal_size
		  else
		    super_size # for breaks to force them...
		  end
          @start_time = Time.now
          cur_index += 1
          self.always_on_top=true
        else
          # avoid weird re-draw text issues
          minutes = (seconds_left/60).to_i          
          if minutes > 0
            current_time = "#{minutes}m"
            set_title current_time
          else
            current_time = "%2ds" % seconds_left
            set_title "#{seconds_left}s" % seconds_left
          end
          @time_remaining_label.set_text current_time
        end
      end
      @switch_image_timer.start
      self.always_on_top=true
  end
  
  Storage = ::Storage.new("pomo_timer")
  Storage.set_default('break_time', 7)
  Storage.set_default('big_break_time', 15)
  Storage.set_default('all_done', [])
  
  def setup_pomo_name minutes
     if minutes > Storage['break_time']
	   if minutes > Storage['big_break_time']
	     begin
           @real_name = SwingHelpers.get_user_input("name for next pomodoro? #{minutes}m", Storage['real_name']) 
		   Storage['all_done'] = Storage['all_done'] + [@real_name] # save history away for now... 
		 rescue Exception => canceled
		   SwingHelpers.hard_exit # so we don't have to shutdown timers, blah blah
		 end
		 Storage['real_name'] = @real_name
         @name = @real_name
		 Thread.new { 
		   sleep 0.5; 
		   SwingHelpers.invoke_in_gui_thread {minimize}
		 }
	   else
	     @name = "big break!"
		end
     else
       @name = "break!"
     end
    @name_label.text=@name
  end
       
end

if $0 == __FILE__
  if ARGV.length == 0
    p 'syntax: minutes1 minutes2 [it will loop, for pomodoro]'
  else
    SwingHelpers.invoke_in_gui_thread { MainWindow.new.show }
  end
end
