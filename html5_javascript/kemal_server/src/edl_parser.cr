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

require 'sane'
require_relative 'convert_thirty_fps'

class EdlParser
  
  def self.on_any_file_changed_single_cached_thread &this_block
    raise unless this_block
    get_files_hash = proc {
      glob = EDL_DIR + '/../**/*'
      Dir[glob].map{|f|
        [f, File.mtime(f)]
      }.sort
    }
    old_value = get_files_hash.call
    @@checking_thread ||= Thread.new {
      loop {
        current_value = get_files_hash.call
        if current_value != old_value
          print 'detected some file was changed! Re-parsing to update...'
          old_value = current_value
          this_block.call
          puts 'done.'
        end
        sleep 2 # 0.02 for size 70, so...hopefully this is ok...
      }
    }
  end

  # this one is 1:01:02.0 => 36692.0
  # its reverse is this: translate_time_to_human_readable
  def self.translate_string_to_seconds s
    # might actually already be a float, or int, depending on the yaml
    # int for 8 => 9 and also for 1:09 => 1:10
    if s.is_a? Numeric
      return s.to_f # easy out.
    end
    
    s = s.strip
    # s is like 1:01:02.0
    total = 0.0
    seconds = nil
    seconds = s.split(":")[-1]
    raise 'does not look like a timestamp? ' + seconds.inspect unless seconds =~ /^\d+(|[,.]\d+)$/
    seconds.gsub!(',', '.')
    total += seconds.to_f
    minutes = s.split(":")[-2] || "0"
    total += 60 * minutes.to_i
    hours = s.split(":")[-3] || "0"
    total += 60* 60 * hours.to_i
    total
  end

  EDL_DIR = File.expand_path(__DIR__  + "/../zamples/edit_decision_lists/dvds")
  
  if File::ALT_SEPARATOR
    EDL_DIR.gsub! File::SEPARATOR, File::ALT_SEPARATOR # to_filename...
  end

  # returns {"mutes" => [["00:00", "00:00", string1, string2, ...], ...], "blank_outs" -> [...], "url" => ...}  
  def self.parse_file filename, expand = true
    output = parse_string File.read(filename), filename, []
    # now respect a few options
    if relative = output["take_from_relative_file"]
      new_filename = File.dirname(filename) + '/' + relative
      new_input = parse_file new_filename
      output.merge! new_input
    end
    
    require_relative 'gui/dependencies' # for download methods...
    
    if expand
    
      if output["from_url"] # replacement
        downloaded = SensibleSwing::MainWindow.download_to_string(output["from_url"])
        output = parse_string downloaded # full replacement
      end
      
      if imdb_id = output["imdb_id"]
        parse_imdb output, imdb_id
      end
    end
    output
  end
  
  def self.parse_imdb output, imdb_id
    require_relative 'convert_thirty_fps'
    url = "http://www.imdb.com/title/#{imdb_id}/parentalguide"
    all = SensibleSwing::MainWindow.download_to_string(url)
    
    header, violence_word, violence_section, profanity_word, profanity_section, alcohol_word, alcohol_section, frightening_word, frightening_section = 
    sections = all.split(/<span>(Violence|Profanity|Alcohol|Frightening)/)
    header = sections.shift
    all ={}
    while(!sections.empty?) # my klugey to_hash method
      word_type = sections.shift
      settings = sections.shift
      assert word_type.in? ['Violence', 'Profanity', 'Alcohol', 'Frightening']
      all[word_type] = settings
    end
    # blank_outs or mutes for each...
    # TODO make the -> optional
    split_into_timestamps = /([\d:]+(?:\.\d+|))\W*-&gt;\W*([\d:]+(?:\.\d+|))([^\d\n]+)/
    for type, settings in all
      settings.scan(split_into_timestamps) do |begin_ts, end_ts, description|
        puts "parsing from wiki imdb  entry violence: #{begin_ts} #{end_ts} #{description} #{type}"
        start_seconds = translate_string_to_seconds begin_ts
        end_seconds = translate_string_to_seconds end_ts
        # convert from 30 to 29.97 fps ... we presume ...
        start_seconds = ConvertThirtyFps.from_twenty_nine_nine_seven start_seconds
        start_seconds = ("%.02f" % start_seconds).to_f # round
        start_seconds = translate_time_to_human_readable start_seconds, true
        end_seconds = ConvertThirtyFps.from_twenty_nine_nine_seven end_seconds
        end_seconds = ("%.02f" % end_seconds).to_f # round
        end_seconds = translate_time_to_human_readable end_seconds, true
        p end_seconds
        if type == 'Profanity'
          output['mutes'] << [start_seconds, end_seconds]
        else
          output['blank_outs'] << [start_seconds, end_seconds]
        end
      end
    end
  end
  
  private

  # better eye-ball these before letting people run them, eh? TODO
  # but I couldn't think of any other way to parse the files tho
  def self.parse_string string, filename = nil, ok_categories_array = []
    string = '{' + string + "\n}"
	  begin
      if filename
       raw = eval(string, binding, filename, 0)
      else
       raw = eval string
      end
    rescue Exception => e
      string.strip.lines.to_a[0..-3].each_with_index{|l, idx| # last line doesn't need a comma check
	      orig_line = l
	      l = l.split('#')[0]
		    l = l.strip
      
		    unless l.empty?
		      # todo strip off # comments at the end of lines too...
		      end_char = l[-1..-1]
          if !end_char.in? ['[', '{'] # these are probably ok...
            puts "warning: #{File.basename filename} line #{idx} might be bad: (maybe needs comma after?) " + l unless end_char == ',' 
          end
        end
      }
	    raise SyntaxError.new(e.to_s) # to_s as a workaround for jruby #6353
	  end
    
    raise SyntaxError.new("maybe missing quotation marks somewhere?" + string) if raw.keys.contain?(nil)
    
    # mutes and blank_outs need to be special parsed into arrays...
    mutes = raw["mutes"] || []
    blanks = raw["blank_outs"] || []
    raw["mutes"] = convert_to_timestamp_arrays(mutes, ok_categories_array)
    raw["blank_outs"] = convert_to_timestamp_arrays(blanks, ok_categories_array)
    raw
  end
  
  # converts "blanks" => ["00:00:00", "00", "reason", "01", "01", "02", "02"] into sane arrays, also filters based on category, though not used in production
  def self.convert_to_timestamp_arrays array, ok_categories_array
    out = []
    while(single_element = extract_entry!(array))
      # assume that it (could be, at least) start_time, end_time, category, number
      category = single_element[-2]
      category_number = single_element[-1]
      include = true
      if ok_categories_array.index([category, category_number])
       include = false
      elsif ok_categories_array.index([category])
       include = false
      elsif ok_categories_array.detect{|cat, setting| setting.is_a? Fixnum}
       for cat, setting in ok_categories_array
         if cat == category && setting.is_a?(Fixnum)
            # check for a number for filtering out based on level
            if category_number.to_i.to_s == category_number
              as_number = category_number.to_i
              if as_number < setting
                include = false
              end
            end
         end
       end

      end
      out << single_element if include
    end
    out
  end
  
  # TimeStamp = /(^\d+:\d\d[\d:\.]*$|\d+)/ # this one also allows for 4444 [?] and also weirdness like "don't kill the nice butterfly 2!" ...
  TimeStamp = /^\s*(\d+:\d\d[\d:\.]*|\d+\.\d+)\s*$/ # allow 00:00:00 00:00:00.0 1222.4 " 2:04 "
  # disallow's 1905 too but elsewhere in the code
  
  def self.extract_entry! from_this
    return nil if from_this.length == 0
    # two digits, then whatever else you see, that's not a digit...
    out = from_this.shift(2)
    out.each{|d|
      unless d =~ TimeStamp
        raise SyntaxError.new('non timestamp? ' + d.inspect) 
      end
    }
    while(from_this[0] && from_this[0] !~ TimeStamp)
      raise SyntaxError.new('straight digits not allowed use 1000.0 instead') if from_this[0] =~ /^\d+$/
      out << from_this.shift
    end
    out
  end
  
  public 
  
  # called later, from external files
  # divides up mutes and blanks so that they don't overlap, preferring blanks over mutes
  # returns it like [[start,end,type], [s,e,t]...] type like either :blank and :mute
  # [ [70.0, 73.0, :blank], [378.0, 379.1, :mute], ... ]
  def self.convert_incoming_to_split_sectors incoming, add_this_to_all_ends = 0, subtract_this_from_beginnings = 0, splits = [], subtract_this_from_ends = 0
    raise if subtract_this_from_beginnings < 0
    raise if add_this_to_all_ends < 0
    raise if subtract_this_from_ends < 0
    add_this_to_all_ends -= subtract_this_from_ends # now we allow negative :)
   # raise if splits.size > 0 # just ignore them for now
    mutes = incoming["mutes"] || {}
    blanks = incoming["blank_outs"] || {}
    mutes = mutes.map{|k, v| [k,v,:mute]}
    blanks = blanks.map{|k, v| [k,v,:blank]}
    combined = (mutes+blanks).map{|s,e,type|  [translate_string_to_seconds(s),  translate_string_to_seconds(e), type]}.sort
    
    # detect any weirdness...
    previous = nil
    combined.map!{ |current|
      s,e,type = current
	  human_s = translate_time_to_human_readable s
	  human_e = translate_time_to_human_readable e
      if e < s || !s || !e || !type
	   p caller
       raise SyntaxError.new("detected an end before a start or other weirdness: #{human_s} > #{human_e}")
      end
      if previous
        ps, previous_end, pt = previous
        if (s < previous_end)
          raise SyntaxError.new("detected an overlap current #{human_s} < #{translate_time_to_human_readable previous_end} of current: #{current.join(' ')} previous: #{previous.join(' ')}")
        end
      end
      previous = current
      # do the math later to allow for ones that barely hit into each other 1.0 2.0, 2.0 3.0
      [s-subtract_this_from_beginnings, e+add_this_to_all_ends,type]
    }
    combined
  end
  
  
  # its reverse: translate_string_to_seconds
  def self.translate_time_to_human_readable seconds, force_hour_stamp = false
    # 3600 => "1:00:00"
    out = ''
    hours = seconds.to_i / 3600
    if hours > 0 || force_hour_stamp
      out << "%d" % hours
      out << ":"
    end
    seconds = seconds - hours*3600
    minutes = seconds.to_i / 60
    out << "%02d" % minutes
    seconds = seconds - minutes * 60
    out << ":"
    
    # avoid an ugly .0 at the end
#    if seconds == seconds.to_i
#      out << "%02d" % seconds
#    else
      out << "%05.2f" % seconds # man that printf syntax is tricky...
#    end
    
  end
  
  def self.all_edl_files_parsed use_all_not_just_dvds
    dir = EDL_DIR
    dir += "/.." if use_all_not_just_dvds
    Dir[dir + '/**/*.txt'].map{|filename|
        begin
          parsed = parse_file(filename)
          [filename, parsed]
        rescue SyntaxError => e
          # ignore poorly formed edit lists for the auto choose phase...
          puts 'warning, unable to parse a file:' + filename + " " + e.to_s
          nil
        end
     }.compact
  end
  
  # returns single matching filename
  # requires a block
  def self.find_single_edit_list_matching use_all_not_just_dvd_dir = false, return_first_if_there_are_several = false
    matching = all_edl_files_parsed(use_all_not_just_dvd_dir).map{|filename, parsed|
      yield(parsed) ? filename : nil
    }.compact
    if matching.length == 1
      file = matching[0]
      file
    elsif matching.length > 1
          p "found multiple matches for media? #{matching.inspect}"
	  if return_first_if_there_are_several
	    matching[0]
	  else
            nil
	  end
    else
      nil
    end
  end
  
  def self.single_edit_list_matches_dvd dvd_id, return_first_if_there_are_several = false
    return nil unless dvd_id
    find_single_edit_list_matching(false, return_first_if_there_are_several)  {|parsed|
      parsed["disk_unique_id"] == dvd_id
    }
  end
  
  def self.convert_to_dvd_nav_times combined, start_type, start_mpeg_time, dvd_nav_packet_offsets, time_multiplier
    start_dvdnav_time = dvd_nav_packet_offsets[1] - dvd_nav_packet_offsets[0]
    raise unless start_type == 'dvd_start_offset' # for now :P
    out = []
    add_this_to_all_of_them = start_dvdnav_time - start_mpeg_time
    #[[70.0, 73.0, :blank], [378.0, 379.1, :mute]]
    for start, endy, type in combined
     if time_multiplier == 30
       # ok
     elsif time_multiplier == 29.97
       start = ConvertThirtyFps.from_twenty_nine_nine_seven start
       endy  = ConvertThirtyFps.from_twenty_nine_nine_seven endy
    else
      raise time_multiplier
    end
    start += start_dvdnav_time
    endy += start_dvdnav_time
    out << [start, endy, type]
   end
   out
  end
  
end

# == 1.8.7 1.9 Symbol compat

class Symbol
  # Standard in ruby 1.9. See official documentation[http://ruby-doc.org/core-1.9/classes/Symbol.html]
  def <=>(with)
    return nil unless with.is_a? Symbol
    to_s <=> with.to_s
  end unless method_defined? :"<=>"
end

if $0 == __FILE__
  p 'syntax: filename'
  require 'rubygems'
  require 'sane'
  parsed = EdlParser.parse_file(*ARGV)
  p 'parsed well'
  p parsed
  require 'yaml'
  print YAML.dump parsed
end
