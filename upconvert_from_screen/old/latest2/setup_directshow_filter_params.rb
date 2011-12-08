# taken from https://github.com/rdp/open-source-directshow-screen-capture-filter/tree/master/configuration_setup_utility

class SetupDirectshowFilterParams
  
  Settings = ['height', 'width', 'start_x', 'start_y']
 
  def initialize
    require 'win32/registry'
    @screen_reg = Win32::Registry::HKEY_CURRENT_USER.create "Software\\os_screen_capture" # LODO .keys fails?
  end
  
  def set_single_setting name, value
    raise unless Settings.include?(name)
    raise unless value.is_a? Fixnum
#    raise value.to_s if value < 0
    @screen_reg.write(name, Win32::Registry::REG_DWORD, value.to_i)
  end
  
  # can be nil if not set...
  def read_single_setting name
    @screen_reg[name]
  end
  
  def teardown
    @screen_reg.close
    @screen_reg = nil
  end
  
end