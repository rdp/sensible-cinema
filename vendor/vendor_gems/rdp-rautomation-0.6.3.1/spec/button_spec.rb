require 'spec_helper'

describe RAutomation::Button do
  it "#button" do
    RAutomation::Window.new(:title => SpecHelper::DATA[:window1_title]).
      button(:value => "Close").should exist

    RAutomation::Window.wait_timeout = 0.1
    expect {RAutomation::Window.new(:title => "non-existing-window").button(:value => "Something")}.
      to raise_exception(RAutomation::UnknownWindowException)
  end

  it "#value" do
    RAutomation::Window.new(:title => SpecHelper::DATA[:window1_title]).
      button(:value => "Close").value.should == "Close"

    RAutomation::Window.wait_timeout = 0.1
    expect {RAutomation::Window.new(:title => SpecHelper::DATA[:window1_title]).button(:value => "non-existent-button").value}.
      to raise_exception(RAutomation::UnknownButtonException)
  end

  it "#exists?" do
    window = RAutomation::Window.new(:title => SpecHelper::DATA[:window1_title])
    window.button(:value => "Close").should exist
    window.button(:value => "non-existent-button").should_not exist
  end

  it "clicking non-existing button raises exception" do
    window = RAutomation::Window.new(:title => SpecHelper::DATA[:window1_title])
    RAutomation::Window.wait_timeout = 0.1
    expect {window.button(:value => "non-existent-button").click}.
      to raise_exception(RAutomation::UnknownButtonException)
  end

  it "#click" do
    window = RAutomation::Window.new(:title => SpecHelper::DATA[:window1_title])

    button = window.button(:value => "Close")
    button.should exist
    button.click

    button.should_not exist
    window.should_not exist
  end

  it "#click with a block for defining successful click returning false raises a TimeoutError" do
    window = RAutomation::Window.new(:title => SpecHelper::DATA[:window1_title])
    RAutomation::Window.wait_timeout = 5
    button = window.button(:value => "Close")
    expect {button.click {false}}.
      to raise_exception(RAutomation::WaitHelper::TimeoutError)

    button.should_not exist
    window.should_not exist
  end

  it "#click with a block for defining successful click returning true" do
    RAutomation::Window.wait_timeout = 10
    window = RAutomation::Window.new(:title => SpecHelper::DATA[:window1_title])
    button = window.button(:value => "Close")
    button.should exist
    button.click {|button| !button.exists? && !window.exists?}

    button.should_not exist
    window.should_not exist
  end

end
