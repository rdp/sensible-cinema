require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Win32::Screenshot::Util do
  include SpecHelper

  before :all do
    # should not have any running calculators yet...
    proc {Win32::Screenshot::Util.window_hwnd("Calculator") }.should raise_exception("window with title 'Calculator' was not found!")
    @calc = IO.popen("calc").pid
    wait_for_calculator_to_open
    @calc_hwnd = Win32::Screenshot::Util.window_hwnd("Calculator")
  end

  it ".all_desktop_windows enumerates all available windows" do
    all_windows = Win32::Screenshot::Util.all_desktop_windows
    all_windows.should_not be_empty
    all_windows[0].should be_an(Array)
    all_windows[0][0].should be_a(String)
    all_windows[0][1].should be_a(Fixnum)

    calculator = all_windows.find {|title, hwnd| title =~ /Calculator/}
    calculator.should_not be_nil
    calculator[0].should == "Calculator"
    calculator[1].should == @calc_hwnd
  end

  it ".window_title returns title of a specified window's handle" do
    Win32::Screenshot::Util.window_title(@calc_hwnd).should == "Calculator"
  end

  it ".dimensions_for window handle returns dimensions of the window in pixels" do
    width, height = Win32::Screenshot::Util.dimensions_for(@calc_hwnd)
    width.should be > 100
    height.should be > 100
  end
  
  it ".window_class returns classname of a specified window's handle" do
    Win32::Screenshot::Util.window_class(@calc_hwnd).should == "CalcFrame"
  end
  
  it ".get_info returns lots of info about an hwnd" do
    desktop_hwnd = Win32::Screenshot::BitmapMaker.desktop_window
    info = Win32::Screenshot::Util.get_info desktop_hwnd
    info.should be_a Hash
    info.keys.sort.should == [:title, :class, :dimensions, :starting_coordinates].sort
  end
  
  it ".windows_hierarchy returns hwnds" do
    a = Win32::Screenshot::Util.windows_hierarchy
    # should have root as "desktop"
    # though in reality some windows might not be descendants of the desktop 
    # (see the WinCheat source which discusses this further)
    # but we don't worry about that edge case yet
    a.should be_a Hash
    a[:children].should be_an Array
    a[:children].length.should be > 0
    a[:children][0].should be_a Hash
    a[:hwnd].should == Win32::Screenshot::BitmapMaker.desktop_window
  end
  
  it ".windows_hierarchy can return info" do
    a = Win32::Screenshot::Util.windows_hierarchy true
    # check for right structure
    for hash_example in [a, a[:children][0]] do
      hash_example.keys.sort.should == [:title, :hwnd, :class, :dimensions, :starting_coordinates, :children].sort
    end
  end
  
  after :all do
    # tests our hwnd -> pid method, and conveniently, shuts down the calculator process
    calc_pid = Win32::Screenshot::Util.window_process_id(@calc_hwnd)
    system("taskkill /PID #{calc_pid}")
    proc {Win32::Screenshot::Util.window_hwnd("Calculator") }.should raise_exception("window with title 'Calculator' was not found!")
  end
end