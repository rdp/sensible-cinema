require 'spec_helper'

describe "WinFfi::Label", :if => SpecHelper.adapter == :win_ffi do
  it "#exist?" do
    window = RAutomation::Window.new(:title => "MainFormWindow")

    window.label(:value => "This is a sample text").should exist
    window.label(:value => "This label should not exist").should_not exist
  end

  it "check for label class" do
    RAutomation::Window.new(:title => "MainFormWindow").label(:id => "textField").should_not exist
  end


  it "#label" do
    window = RAutomation::Window.new(:title => "MainFormWindow")

    window.label(:value => "This is a sample text").value.should == "This is a sample text"
  end
end
