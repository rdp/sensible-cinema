require "spec"
require "../subtitle_profanity_finder"

describe SubtitleProfanityFinder do
  describe "parsenormal" do
    it "should parse 'em" do
      mutes, euphes = SubtitleProfanityFinder.mutes_from_srt_string File.read("Awakenings.1990.1080p.BluRay.X264-AMIABLE.HI.srt")
      mutes.size.should eq 6
      euphes.size.should eq 1331
    end
  end
end

