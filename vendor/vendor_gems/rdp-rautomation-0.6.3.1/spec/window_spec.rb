require 'spec_helper'

describe RAutomation::Window do
  it "RAutomation::Window.adapter" do
    RAutomation::Window.new(:title => "random").adapter.should == (ENV["RAUTOMATION_ADAPTER"] && ENV["RAUTOMATION_ADAPTER"].to_sym || RAutomation::Adapter::Helper.default_adapter)
  end

  it "Window#new by full title" do
    RAutomation::Window.new(:title => SpecHelper::DATA[:window1_full_title]).should exist
  end

  it "Window#new by regexp title" do
    RAutomation::Window.new(:title => SpecHelper::DATA[:window1_title]).should exist
  end

  it "Window#new by hwnd" do
    hwnd = RAutomation::Window.new(:title => SpecHelper::DATA[:window1_full_title]).hwnd
    window = RAutomation::Window.new(:hwnd => hwnd)
    window.should exist
    window.title.should == SpecHelper::DATA[:window1_full_title]
  end

  it "#exists?" do
    RAutomation::Window.new(:title => SpecHelper::DATA[:window1_title]).should exist
    RAutomation::Window.new(:title => "non-existing-window").should_not exist
  end

  it "#visible?"do
    RAutomation::Window.new(:title => SpecHelper::DATA[:window1_title]).should be_visible
    RAutomation::Window.wait_timeout = 0.1
    expect {RAutomation::Window.new(:title => "non-existing-window").visible?}.
            to raise_exception(RAutomation::UnknownWindowException)
  end

  it "#present?"do
    RAutomation::Window.new(:title => SpecHelper::DATA[:window1_title]).should be_present
    RAutomation::Window.new(:title => "non-existing-window").should_not be_present
  end

  it "#hwnd" do
    RAutomation::Window.new(:title => SpecHelper::DATA[:window1_title]).hwnd.should be_a(Fixnum)
    RAutomation::Window.wait_timeout = 0.1
    expect {RAutomation::Window.new(:title => "non-existing-window").hwnd}.
            to raise_exception(RAutomation::UnknownWindowException)
  end

  it "#title" do
    RAutomation::Window.new(:title => SpecHelper::DATA[:window1_title]).title.should == SpecHelper::DATA[:window1_full_title]
    RAutomation::Window.wait_timeout = 0.1
    expect {RAutomation::Window.new(:title => "non-existing-window").title}.
            to raise_exception(RAutomation::UnknownWindowException)
  end

  it "#activate & #active?" do
    window = RAutomation::Window.new(:title => SpecHelper::DATA[:window1_title])
    window.activate
    window.should be_active
    non_existing_window = RAutomation::Window.new(:title => "non-existing-window")
    non_existing_window.activate
    non_existing_window.should_not be_active
  end

  it "#text" do
    RAutomation::Window.new(:title => SpecHelper::DATA[:window1_title]).text.should include(SpecHelper::DATA[:window1_text])
    RAutomation::Window.wait_timeout = 0.1
    expect {RAutomation::Window.new(:title => "non-existing-window").text}.
            to raise_exception(RAutomation::UnknownWindowException)
  end

  it "#maximize" do
    RAutomation::Window.new(:title => SpecHelper::DATA[:window1_title]).maximize
    RAutomation::Window.wait_timeout = 0.1
    expect {RAutomation::Window.new(:title => "non-existing-window").maximize}.
            to raise_exception(RAutomation::UnknownWindowException)
  end

  it "#minimize & #minimized?" do
    window = RAutomation::Window.new(:title => SpecHelper::DATA[:window1_title])
    window.should_not be_minimized
    window.minimize
    window.should be_minimized

    RAutomation::Window.wait_timeout = 0.1
    expect {RAutomation::Window.new(:title => "non-existing-window").minimize}.
            to raise_exception(RAutomation::UnknownWindowException)
    expect {RAutomation::Window.new(:title => "non-existing-window").minimized?}.
            to raise_exception(RAutomation::UnknownWindowException)
  end

  it "#restore" do
    RAutomation::Window.new(:title => SpecHelper::DATA[:window1_title]).restore
    RAutomation::Window.wait_timeout = 0.1
    expect {RAutomation::Window.new(:title => "non-existing-window").restore}.
            to raise_exception(RAutomation::UnknownWindowException)
  end

  it "#method_missing" do
    win = RAutomation::Window.new(:title => SpecHelper::DATA[:window1_title])
    SpecHelper::DATA[:title_proc].call(win).should == SpecHelper::DATA[:window1_full_title]
  end

  it "#send_keys"do
    window = RAutomation::Window.new(:title => SpecHelper::DATA[:window1_title])
    window.minimize # send_keys should work even if window is minimized
    window.send_keys(SpecHelper::DATA[:window1_send_keys])
    SpecHelper::DATA[:proc_after_send_keys].call

    RAutomation::Window.wait_timeout = 0.1
    expect {RAutomation::Window.new(:title => "non-existing-window").send_keys("123")}.
            to raise_exception(RAutomation::UnknownWindowException)
  end

  it "#close" do
    window = RAutomation::Window.new(:title => SpecHelper::DATA[:window1_title])
    window.should exist
    window.close
    window.should_not exist

    expect {RAutomation::Window.new(:title => "non-existing-window").close}.
            to_not raise_exception
  end
end
