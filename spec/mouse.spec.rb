require File.expand_path(File.dirname(__FILE__) + '/common')
require_relative '../lib/mouse'

describe Mouse do

  it "should move it a couple times" do
    old = Mouse.total_movements
    begin
    Timeout::timeout(2) {
      Mouse::jitter_forever_in_own_thread.join
    }
    rescue Timeout::Error
    end
    Mouse.total_movements.should be > old
  end
  
  it "should not move it if the user does" do
    old = Mouse.total_movements
    begin
    Timeout::timeout(2) {
      Mouse::jitter_forever_in_own_thread
      x = 1
      loop {java.awt.Robot.new.mouse_move(500 + (x+=1),500); sleep 0.1; }
    }
    rescue Timeout::Error
    end
    Mouse.total_movements.should == old + 1
  
  end
  
  

end