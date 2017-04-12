require "spec"
require "../database_objects"

describe Url do
  it "should have human time" do
    url = Url.new
    url.total_time = 1*3600 + 4*60 + 33.17 # 1hr 4m 33.17s
    url.human_duration.should eq "1hr 4m"
  end

  it "should have empty human time if none" do
    url = Url.new
    url.human_duration.should eq ""
  end

  it "should not show 0hr" do
    url = Url.new
    url.total_time = 4*60 + 33.17 # 4m 33.17s
    url.human_duration.should eq "4m"
  end
end
