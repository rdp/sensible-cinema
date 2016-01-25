require "spec_helper"

describe "WinFfi::Window", :if => SpecHelper.adapter == :win_ffi do
  it "#child" do
    window = RAutomation::Window.new(:title => /MainFormWindow/i)
    window.should exist

    # buttons are windows too. so let's find the button for now
    child = window.child(:title => /About/i)
    child.should exist
    child.title.should == "&About"
    #    child.text.should include "About"
  end

  it "send tab keystrokes to move focus between elements" do
    window = RAutomation::Window.new(:title => /MainFormWindow/i)
    window.button(:value => "&About").set_focus
    window.button(:value => "&About").should have_focus

    window.send_keys("{tab}{tab}{tab}")
    button = window.button(:value => "Close")
    button.should exist
    button.should have_focus
  end

   it "send keystrokes to a text field" do
    window = RAutomation::Window.new(:title => /MainFormWindow/i)
    text_field = RAutomation::Window.new(:title => "MainFormWindow").text_field(:id => "textField")
    text_field.set_focus
    window.send_keys("abc123ABChiHI")
    text_field.value.should == "abc123ABChiHI"
   end

  it "#control" do
    window = RAutomation::Window.new(:title => /MainFormWindow/i)
    window.control(:id => "aboutButton").should exist
  end

  it "has controls" do
    window = RAutomation::Window.new(:title => /MainFormWindow/i)
    window.controls(:class => /BUTTON/i).size.should == 12
  end
end
