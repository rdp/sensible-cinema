=begin
Copyright 2010, Roger Pack 
This file is part of Sensible Cinema.

    Sensible Cinema is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Sensible Cinema is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Sensible Cinema.  If not, see <http://www.gnu.org/licenses/>.
=end

require File.expand_path(File.dirname(__FILE__) + '/common')
require_relative '../lib/subtitle_profanity_finder'
require 'sane'

describe SubtitleProfanityFinder do

  describe "should parse out various profanities" do
    
    output = SubtitleProfanityFinder.edl_output 'dragon.srt'

    describe "he.." do
      it "should include the bad line with timestamp" do
        output.should match(/0:00:54.93.*"he\.\."/)
      end
    
      it "should include the description in its output" do
        output.should include("e [he..] b")
      end
    end
    
    describe "deity various" do
      it "should parse output plural deity" do
        output.should include("nordic [deitys] ")
      end
      
      it "should parse out deity singular and at very end" do
        output = SubtitleProfanityFinder.edl_output 'deity_end.srt'
        output.should include("fortress is our [goodness]")
      end
      
      it "should parse out <i> et al " do
        output = SubtitleProfanityFinder.edl_output 'deity_end.srt'
        output.should_not include(" i ")
        output.should_not include("<i")
        output.should_not include("huntingand")
        output.should_not include("   ")
      end
      
    end
    
    describe 'full word only profanities' do
      
      output2 =  SubtitleProfanityFinder.edl_output 'arse.srt'
      
      it 'should not parse it if it\'s in other words' do
        output2.should_not include "a..ume"
        output2.should_not include "he..o" # todo: positive ex: ... :P
      end
      
      it 'should parse them at EOL' do
        output2.should include '0:00:55.07' # EOL
        output2.should include "0:00:55.07" # full line...
        output2.should include '0:00:55.07' # BOL TODO fix spec :P
      end
      
      it 'should replace l for i' do
        output2.should include "07" # implies it got the substutition right...
      end
      
      it 'should keep apostrophes' do
        output2.should include "don't"
      end
      
      it 'should not disdain impass' do
        output2.should_not include "impa.."
      end
      
    end
    
  end
  
  it 'should add to begin, end' do
    out = SubtitleProfanityFinder.edl_output 'dragon.srt', {'word' => 'word'}, 1, 1.5
    out.should include "45.46"
    out.should include "51.59"
  end
  
  it "should accomodate lesser profanities" do
    out = SubtitleProfanityFinder.edl_output_from_string <<-EOL, {}, 0, 0, 0, 0, 100, 100
6
00:00:55,068 --> 00:00:59,164
a butt

    EOL
    out.should include "55.0"

  end
  
  describe "it should take optional user params" do
    output = SubtitleProfanityFinder.edl_output 'dragon.srt', {'word' => 'word'}
    
    it "should parse out the word word" do
      output.should match(/0:00:50.09.*"word"/)
    end
    
    it "should parse out and replace with euphemism" do
      output = SubtitleProfanityFinder.edl_output 'dragon.srt', {'word' => 'w...'}
      output.should match(/0:00:50.09.*In a \[w\.\.\.\]/)
    end
    
  end

  S = SubtitleProfanityFinder

  describe "it should let you re-factor the timestamps on the fly if desired"  do

#  def self.edl_output_from_string subtitles, extra_profanity_hash, subtract_from_each_beginning_ts, add_to_end_each_ts, starting_timestamp_given, starting_timestamp_actual, ending_timestamp_given, ending_timestamp_actual^M

    it "should subtract from beginning etc. etc." do
       normal = S.edl_output 'dragon.srt'
       normal.should =~ /0:00:50.23/
       normal.should =~ /0:00:54.93/
       subtract = S.edl_output 'dragon.srt', {}, 1.0
       subtract.should =~ /0:00:49.23/
       normal.should =~ /0:00:54.93/
       add = S.edl_output 'dragon.srt', {}, 0.0, 1.0
       add.should =~ /0:00:55.93/
       add.should =~ /0:00:50.23/
    end

    it "should compensate for differing start timestamps" do
       starts_ten_later_than_srt = S.edl_output 'dragon.srt', {}, 0.0, 0.0, "00:10", "00:20"
       starts_ten_later_than_srt.should =~ /0:01:00.22/
       starts_ten_later_than_srt.should =~ /0:01:04.93/
    end

   it "should compensate for differing end timestamps with a multiple" do
     lasts_longer = S.edl_output 'dragon.srt', {}, 0.0, 0.0, "00:00", "00:00", "01:00", "01:30" # actual ends 50% later
     lasts_longer.should =~ /0:01:15.34/
     lasts_longer.should =~ /0:01:22.39/
   end

    describe "combining different initial time offsets with total times" do

     it "should combine different initial time offset with different total time" do
      lasts_longer_with_initial_add =  S.edl_output 'dragon.srt', {}, 0.0, 0.0, begin_srt = "00:00", begin_actual = "00:10", end_srt = "00:55", end_actual = "00:55" 
      # this one starts off weird, but then ends at almost exactly the same!
      lasts_longer_with_initial_add.should =~ /0:00:51.10/
      lasts_longer_with_initial_add.should =~ /0:00:54.94/ # note--almost on
     end

     it "should be ok if they line up perfectly with just an offset" do
       plus_ten = S.edl_output 'dragon.srt', {}, 0.0, 0.0, begin_srt = "00:00", begin_actual = "00:10", end_srt = "00:55", end_actual = "01:05"
       plus_ten.should =~ /0:01:00.23/
       plus_ten.should =~ /0:01:04.93/
     end

    end

  end
  
end
