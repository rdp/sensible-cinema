require "spec"
require "../database_objects"

describe Url do
  it "should have human time" do
    url = Url.new
    url.total_time = 1*3600 + 4*60 + 33.17 # 1:4:33.17
    url.human_duration.should eq "1hr 4m"
  end
end
