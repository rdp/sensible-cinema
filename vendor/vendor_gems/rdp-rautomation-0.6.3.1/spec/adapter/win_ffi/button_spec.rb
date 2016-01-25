require 'spec_helper'

describe "WinFfi::Button", :if => SpecHelper.adapter == :win_ffi do
  it "find by id" do
    window = RAutomation::Window.new(:title => SpecHelper::DATA[:window1_title])
    window.button(:id => "aboutButton").should exist
  end

  it "check for button class" do
    RAutomation::Window.new(:title => "MainFormWindow").button(:id => "textField").should_not exist
  end


  it "enabled/disabled" do
    window = RAutomation::Window.new(:title => SpecHelper::DATA[:window1_title])
    window.button(:id => "enabledButton").should be_enabled
    window.button(:id => "enabledButton").should_not be_disabled

    window.button(:id => "disabledButton").should be_disabled
    window.button(:id => "disabledButton").should_not be_enabled
  end

  it "#set_focus" do
    button = RAutomation::Window.new(:title => SpecHelper::DATA[:window1_title]).button(:id => "enabledButton")
    button.should_not have_focus

    button.set_focus
    button.should have_focus
  end

  it "cannot click disabled button" do
    window = RAutomation::Window.new(:title => SpecHelper::DATA[:window1_title])
    lambda { window.button(:id => "disabledButton").click }.should raise_error
  end

  it "cannot set focus to disabled button" do
    window = RAutomation::Window.new(:title => SpecHelper::DATA[:window1_title])
    lambda { window.button(:id => "disabledButton").set_focus }.should raise_error
  end

end