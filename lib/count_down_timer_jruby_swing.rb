require 'rubygems'
require 'sane'
require_relative '../lib/swing_helpers'

module SensibleSwing

class MainWindow < JFrame

  def show_blocking_message_dialog(message, title = message.split("\n")[0], style= JOptionPane::INFORMATION_MESSAGE)
# I think I'm already on top...
 setVisible(true);
 toFront()
    JOptionPane.showMessageDialog(nil, message, title, style)
    true
  end

  def initialize
      super "countdown"
      set_size 150,100
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
      
      starting_seconds_requested = (ARGV[0] || '25').to_f*60
      @switch_image_timer = javax.swing.Timer.new(1000, nil) # nil means it has no default person to call when the action has occurred...
      @switch_image_timer.add_action_listener do |e|
        seconds_left = starting_seconds_requested - (Time.now - @start_time)
        if seconds_left < 0
          setVisible(true)
          toFront()
          show_blocking_message_dialog "timer done!"
          @start_time = Time.now
        else
          # avoid weird re-draw issues
          @jlabel.set_text "%02d:%02d" % [seconds_left/60, seconds_left % 60]
        end
      end
      @switch_image_timer.start
      self.always_on_top=true
  end
  
  end

  MainWindow.new.show

end