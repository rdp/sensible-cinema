require 'spec_helper'

describe RAutomation::Windows do
  subject {self}

  before :each do
    @pid2 = IO.popen(SpecHelper::DATA[:window2]).pid
    window = RAutomation::Window.new(:pid => @pid2)
    RAutomation::WaitHelper.wait_until {window.present?}
  end

  it "Window.windows returns all windows" do
    windows = RAutomation::Window.windows
    windows.should be_a(RAutomation::Windows)
    windows.size.should be >= 2
    expected_windows = [
      RAutomation::Window.new(:pid => @pid1),
      RAutomation::Window.new(:pid => @pid2)
    ]
    should have_all_windows(expected_windows, windows)
  end

  it "Windows#windows returns all similar windows" do
    windows = RAutomation::Window.new(:title => SpecHelper::DATA[:window1_title]).windows
    windows.should be_a(RAutomation::Windows)
    windows.size.should == 1
    expected_windows = [
      RAutomation::Window.new(:pid => @pid1),
    ]
    should have_all_windows(expected_windows, windows)
  end

  it "Windows#windows with parameters returns all matching windows" do
    windows = RAutomation::Window.new(:title => SpecHelper::DATA[:window1_title]).windows(:title => SpecHelper::DATA[:window2_title])
    windows.should be_a(RAutomation::Windows)

    windows.size.should == 1
    expected_windows = [
      RAutomation::Window.new(:pid => @pid2),
    ]
    should have_all_windows(expected_windows, windows)
  end

  after :each do
    Process.kill(9, @pid2) rescue nil    
  end

  def has_all_windows?(expected_windows, windows)
    expected_windows.all? do |expected_window|
      matched_windows = windows.find_all {|win| win.hwnd == expected_window.hwnd}
      matched_windows.size == 1
    end
  end

end
