require 'spec_helper'

describe RAutomation::TextField do
  it "#text_field" do
    RAutomation::Window.new(:title => "MainFormWindow").
        text_field(:id => "textField").should exist

    RAutomation::Window.wait_timeout = 0.1
    expect { RAutomation::Window.new(:title => "non-existent-window").
        text_field(:class => "Edit") }.
        to raise_exception(RAutomation::UnknownWindowException)
  end

  it "#set" do
    window = RAutomation::Window.new(:title => "MainFormWindow")
    window.text_field(:id => "textField").set "hello!"

    RAutomation::Window.wait_timeout = 0.1
    expect { window.text_field(:class => "non-existing-field").set "hello!" }.
        to raise_exception(RAutomation::UnknownTextFieldException)
  end

  it "#clear" do
    window = RAutomation::Window.new(:title => "MainFormWindow")
    field  = window.text_field(:id => "textField")
    field.set "hello!"
    field.value.should == "hello!"
    field.clear
    field.value.should be_empty

    RAutomation::Window.wait_timeout = 0.1
    expect { window.text_field(:class => "non-existent-field").clear }.
        to raise_exception(RAutomation::UnknownTextFieldException)
  end

  it "#value" do
    window = RAutomation::Window.new(:title => "MainFormWindow")
    field  = window.text_field(:id => "textField")
    field.set "hello!"
    field.value.should == "hello!"

    RAutomation::Window.wait_timeout = 0.1
    expect { window.text_field(:class => "non-existent-field").value }.
        to raise_exception(RAutomation::UnknownTextFieldException)
  end

  it "#exists?" do
    window = RAutomation::Window.new(:title => "MainFormWindow")
    field  = window.text_field(:id => "textField")
    field.should exist
    window.text_field(:class => "non-existent-field").should_not exist
  end


  it "#hwnd" do
    window = RAutomation::Window.new(:title => "MainFormWindow")
    field  = window.text_field(:id => "textField")

    field.hwnd.should be_a(Fixnum)

    RAutomation::Window.wait_timeout = 0.1
    expect { window.text_field(:class => "non-existing-window").hwnd }.
        to raise_exception(RAutomation::UnknownTextFieldException)
  end
end
