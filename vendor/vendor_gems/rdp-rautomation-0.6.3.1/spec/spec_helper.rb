$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rautomation'
require 'rspec'

module SpecHelper
  # @private
  def adapter
    ENV["RAUTOMATION_ADAPTER"] && ENV["RAUTOMATION_ADAPTER"].to_sym || RAutomation::Adapter::Helper.default_adapter
  end

  def navigate_to_simple_elements
    main_window = RAutomation::Window.new(:title => "MainFormWindow")
    main_window.button(:value => "Simple Elements").click { RAutomation::Window.new(:title => "SimpleElementsForm").present? }
  end

  module_function :adapter, :navigate_to_simple_elements

  # Since adapters are different then the windows to be tested
  # might be different also.
  #
  # This constant allows to create input data for specs which could differ between the adapters.
  #
  # There has to be 2 windows:
  # 1) Some random window, which is maximizable, minimizable, close'able and etc.
  # 2) Browser window, which opens up a test.html where JavaScript prompt with a Button and a TextField objects will be shown.
  DATA = {
          # This adapter needs Windows OS with Internet Explorer installed into 'c:\program files\internet explorer'.
          :autoit => {
                  # Path to some binary, which opens up a window, what can be
                  # minimized, maximized, activated, closed and etc.
                  :window1 => "ext\\WindowsForms\\bin\\WindowsForms.exe",
                  :window2 => "calc",
                  :window2_title => /calc/i,
                  # Window 1 title, has to be a Regexp.
                  :window1_title => /FormWindow/i,
                  :window1_full_title => 'MainFormWindow',
                  # Window 1 should have this text on it.
                  :window1_text => "This is a sample text",
                  # When sending ENTER on Window 2, then the window OK button should be pressed and Window 2 should be closed.
                  # "A" key
                  :window1_send_keys => "A",
                  :proc_after_send_keys => lambda do
                    about_box = RAutomation::Window.new(:title => /About/i)
                    RAutomation::WaitHelper.wait_until {about_box.present?}
                  end,
                  # Window 1 should have a button with the following text.
                  :window1_button_text => "&About",
                  # Window 1 should have a text field with the specified class name.
                  :window1_text_field_class => "Edit",
                  # Adapter internal method invocation for getting title of window2
                  :title_proc => lambda {|win| win.WinGetTitle("[TITLE:MainFormWindow]")}
          },
          :win_ffi => {
                  # Path to some binary, which opens up a window, what can be
                  # minimized, maximized, activated, closed and etc.
                  :window1 => "ext\\WindowsForms\\bin\\WindowsForms.exe",
                  :window2 => "calc",
                  :window2_title => /calc/i,
                  # Window 1 title, has to be a Regexp.
                  :window1_title => /FormWindow/i,
                  :window1_full_title => 'MainFormWindow',
                  # Window 1 should have this text on it.
                  :window1_text => "This is a sample text",
                  # When sending ENTER on Window 2, then the window OK button should be pressed and Window 2 should be closed.
                  # "A" key
                  :window1_send_keys => "A",
                  :proc_after_send_keys => lambda do
                    about_box = RAutomation::Window.new(:title => /About/i)
                    RAutomation::WaitHelper.wait_until {about_box.present?}
                  end,
                  # Window 1 should have a button with the following text.
                  :window1_button_text => "&About",
                  # Window 1 should have a text field with the specified class name.
                  :window1_text_field_class => "Edit",
                  # Adapter internal method invocation for getting title of window2
                  :title_proc => lambda {|win| win.window_title(win.hwnd)}
          },
          :ms_ui_automation => {
              :window1 => "ext\\WindowsForms\\bin\\WindowsForms.exe"
          }
  }[adapter]
end


RSpec.configure do |config|
  config.before(:each) do
    RAutomation::Window.wait_timeout = 60

    @pid1 = IO.popen(SpecHelper::DATA[:window1]).pid
    RAutomation::WaitHelper.wait_until {RAutomation::Window.new(:pid => @pid1).present?}
  end

  config.after(:each) do
    Process.kill(9, @pid1) rescue nil
  end
end
