require 'spec_helper'

describe "WinFfi::ListBox", :if => SpecHelper.adapter == :win_ffi do

  it "#exists" do
    RAutomation::Window.new(:title => "MainFormWindow").list_box(:id => "FruitListBox").should exist
  end

  it "check for listbox class" do
    RAutomation::Window.new(:title => "MainFormWindow").list_box(:id => "textField").should_not exist
  end

  it "counts items" do
    list_box = RAutomation::Window.new(:title => "MainFormWindow").list_box(:id => "FruitListBox")
    list_box.count.should == 3
  end

  it "lists items" do
    list_box = RAutomation::Window.new(:title => "MainFormWindow").list_box(:id => "FruitListBox")
    list_box.items[0].should == "Apple"
    list_box.items[1].should == "Orange"
    list_box.items[2].should == "Mango"
  end


  it "#selected?" do
    list_box = RAutomation::Window.new(:title => "MainFormWindow").list_box(:id => "FruitListBox")

    list_box.selected?(2).should == false
    list_box.select(2)
    list_box.selected?(2).should == true
  end

  it "#select" do
    list_box = RAutomation::Window.new(:title => "MainFormWindow").list_box(:id => "FruitListBox")

    list_box.select(1)
    list_box.selected?(1).should == true

    list_box.select(0)
    list_box.selected?(0).should == true

    list_box.select(2)
    list_box.selected?(2).should == true
  end

  it "#strings" do
    list_box = RAutomation::Window.new(:title => "MainFormWindow").list_box(:id => "FruitListBox")

    list_box.strings.should == ["Apple", "Orange", "Mango"]
  end
end
