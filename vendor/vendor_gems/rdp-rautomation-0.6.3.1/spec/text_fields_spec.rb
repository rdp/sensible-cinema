require 'spec_helper'

describe RAutomation::TextFields do

  it "Window#text_fields returns all text fields" do
    SpecHelper::navigate_to_simple_elements

    text_fields = RAutomation::Window.new(:title => "SimpleElementsForm").text_fields
    text_fields.size.should == 2
    text_fields.find_all {|t| t.value == "Enter some text"}.size.should == 1
  end

  it "Window#text_fields with parameters returns all matching text fields" do
    SpecHelper::navigate_to_simple_elements

    window = RAutomation::Window.new(:title => "SimpleElementsForm")
    text_fields = window.text_fields(:index => 0)
    text_fields.size.should == 2
    text_fields.first.value.should == "Enter some text"
  end

end
