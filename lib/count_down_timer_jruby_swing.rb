require 'rubygems'
require 'sane' # require_relative
require_relative 'jruby-swing-helpers/swing_helpers'

include SwingHelpers
  
class MainWindow < JFrame

  def show_blocking_message_dialog(message, title = message.split("\n")[0], style= JOptionPane::INFORMATION_MESSAGE)
    # I think I'm already on top...
    setVisible(true);
    toFront()
    JOptionPane.showMessageDialog(self, message, title, style)
    true
  end
  
  def set_normal_size
      set_size 165,100
  end
  
  def super_size
    set_size 1650,1000
  end

  def initialize
      super "welcome..."
      set_normal_size
      setAlwaysOnTop true
      setDefaultCloseOperation JFrame::EXIT_ON_CLOSE # happiness
      @jlabel = JLabel.new 'Welcome to Sensible Cinema!'
      happy = Font.new("Tahoma", Font::PLAIN, 11)
      @jlabel.setFont(happy)
      @jlabel.set_bounds(44,44,160,14)
      panel = JPanel.new
      @panel = panel
      @buttons = []
      panel.set_layout nil
      add panel # why can't I just slap these down?
      panel.add @jlabel
      @start_time = Time.now
      @jlabel.set_text 'welcome...'
      
      cur_index = 0
      starting_seconds_requested = ARGV.map{|a| a.to_f*60}
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
          show_blocking_message_dialog "Timer done! #{seconds_requested/60}m at #{Time.now}. Next up #{next_up/60}m." 
          set_normal_size
          @start_time = Time.now
          cur_index += 1
        else
          # avoid weird re-draw issues
          minutes = (seconds_left/60).to_i          
          if minutes > 0
            current_time = "%02d:%02d" % [minutes, seconds_left % 60]
            set_title "#{minutes}m"
          else
            current_time = "%2ds" % seconds_left
            set_title "#{seconds_left}s" % seconds_left
          end
          @jlabel.set_text current_time
        end
      end
      @switch_image_timer.start
      self.always_on_top=true
  end
  
  end

if $0 == __FILE__
  if ARGV.length == 0
    p 'syntax: minutes1 minutes2 [it will loop, for pomodoro]'
  else
    MainWindow.new.show
  end
end

