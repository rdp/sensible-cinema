require 'spec_helper'

describe "WinFfi::Table", :if => SpecHelper.adapter == :win_ffi do
  before :each do
    window = RAutomation::Window.new(:title => "MainFormWindow")
    window.button(:value => "Data Entry Form").click { RAutomation::Window.new(:title => "DataEntryForm").exists? }
  end

  it "#table" do
    table = RAutomation::Window.new(:title => "DataEntryForm").table(:id => "personListView")
    table.should exist
    
    RAutomation::Window.wait_timeout = 0.1
    expect {RAutomation::Window.new(:title => "non-existent-window").
            table(:class => /SysListView32/i)}.
            to raise_exception(RAutomation::UnknownWindowException)
  end

  it "#strings" do
    table = RAutomation::Window.new(:title => "DataEntryForm").table(:id => "personListView")

    table.strings.should == [
        ["Name", "Date of birth", "State"],
        ["John Doe", "12/15/1967", "FL"],
        ["Anna Doe", "3/4/1975", ""]
    ]
  end

  it "#select" do
    table = RAutomation::Window.new(:title => "DataEntryForm").table(:id => "personListView")

    table.selected?(2).should == false

    table.select(2)
    table.selected?(2).should == true
  end

end

