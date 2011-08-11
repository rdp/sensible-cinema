require 'rautomation'
require_relative 'edl_parser'

class AutoWindowFinder
  
  # when they select a file, it contains a...url say...
  # so look for that url, with "this" child window class [?]
  # so basically, if a browser window is "open" to such and such a url
  # and it is mentioned in a file
  # it should find it
  
  
  def self.search_for_single_url_match edl_dir
    matching = EdlParser.all_edl_files_parsed(edl_dir).select{|filename, parsed|
      if parsed["url"]
        window = RAutomation::Window.new(:title => Regexp.new(parsed["url"]))
        window.exist?
      end
    }.compact
    p matching
    if matching.length == 1
      matching[0]
    elsif matching.length > 1
      p 'multiple open windows match a known url?'
      nil
    else
      nil
    end
  end
  
end