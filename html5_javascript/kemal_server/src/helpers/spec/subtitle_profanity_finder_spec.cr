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

  describe "parse amazon" do
    it "should split" do
      splitted = SubtitleProfanityFinder.split_from_amazon File.read("sing.amazon.dfxp")
      splitted.size.should eq 2406
    end

    it "should parse amazon line" do
      outty = SubtitleProfanityFinder.translate_amazon_line_to_entry("<tt:p begin=\"00:03:07.321\" end=\"00:03:10.924\">but I say wonder and magic<tt:br/>don't come easy, pal.</tt:p>").not_nil!
      outty[:beginning_time].should eq 187.321
      outty[:ending_time].should eq 190.924
      outty[:text].should eq "but I say wonder and magic don't come easy, pal. "
    end

    it "should find profanities in amazon stuff" do
      mutes, euphes = SubtitleProfanityFinder.mutes_from_amazon_string File.read("sing.amazon.dfxp")
      mutes.size.should eq 13
      euphes.size.should eq 2406
    end

    it "should find profanities in ttml amazon file" do
      mutes, euphes = SubtitleProfanityFinder.mutes_from_amazon_string File.read("spiderverse.6d5a1b.ttml2")
      mutes.size.should eq 8
      euphes.size.should eq 2271
    end
  end
end
