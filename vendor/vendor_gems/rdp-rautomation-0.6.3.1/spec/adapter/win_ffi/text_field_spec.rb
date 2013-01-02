require 'spec_helper'

describe "WinFfi::TextField", :if => SpecHelper.adapter == :win_ffi do

  it "check for text field class" do
    RAutomation::Window.new(:title => "MainFormWindow").text_field(:id => "checkBox").should_not exist
  end

  it "enabled/disabled" do
    RAutomation::Window.new(:title => "MainFormWindow").text_field(:id => "textField").should be_enabled
    RAutomation::Window.new(:title => "MainFormWindow").text_field(:id => "textField").should_not be_disabled

    RAutomation::Window.new(:title => "MainFormWindow").text_field(:id => "textBoxDisabled").should_not be_enabled
    RAutomation::Window.new(:title => "MainFormWindow").text_field(:id => "textBoxDisabled").should be_disabled
  end

  it "cannot set a value to a disabled text field" do
    lambda { RAutomation::Window.new(:title => "MainFormWindow").text_field(:id => "textBoxDisabled").set "abc" }.should raise_error

    lambda { RAutomation::Window.new(:title => "MainFormWindow").text_field(:id => "textBoxDisabled").clear }.should raise_error
  end

end
