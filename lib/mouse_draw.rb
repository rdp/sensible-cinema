require 'mouse'


class MouseDraw
  
  def self.go
  
  require 'java'

  java_import 'javax.swing.JFrame'
  java_import 'javax.swing.JButton'
  java_import 'com.sun.awt.AWTUtilities'

  f = JFrame.new
  f.add JButton.new('capture window')
  f.set_size(200,200)

  AWTUtilities.set_window_opacity(f, 0.5)
  
  # wait till mouse goes down...
  while(Mouse.left_mouse_button_state == :up)
    sleep 0.05
    print '.'
  end
  f.undecorated = true
  f.default_close_operation = JFrame::EXIT_ON_CLOSE
  f.always_on_top = true
  f.visible = true
  f.set_location(Mouse.get_mouse_location)
  while(Mouse.left_mouse_button_state == :down)
    # set_size
  end
  #f.close
end
  
end


if $0 == __FILE__
  MouseDraw.go
end