require 'rubygems'
require 'sane'
require_relative '../lib/swing_helpers'

module SensibleSwing

class MainWindow < JFrame

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
      Thread.new { sleep 1; @jlabel.set_text 'yo3'}
      
      @switch_image_timer = javax.swing.Timer.new(1000, nil) # nil means it has no default person to call when the action has occurred...
      @switch_image_timer.add_action_listener do |e|
          seconds_left = (ARGV[0] || '35').to_i*60 - (Time.now - @start_time)
          @jlabel.set_text "%02d:%02d" % [seconds_left/60, seconds_left % 60]
      end
      @switch_image_timer.start
      self.always_on_top=true
  end
  
end

MainWindow.new.show

end