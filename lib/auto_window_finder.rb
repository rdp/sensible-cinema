require 'rautomation'
require_relative 'edl_parser'

class AutoWindowFinder
  
  # when they select a file, it contains a...url say...
  # so look for that url, with "this" child window class [?]
  # so basically, if a browser window is "open" to such and such a url
  # and it is mentioned in a file
  # it should find it
  
  def self.search_for_single_url_match edl_dir
    EdlParser.find_single_edit_list_matching(edl_dir){|parsed|
      if url = parsed["url"]
        window = RAutomation::Window.new(:title => Regexp.new(url)) # can this even work though? Do I need a title?
        window.exist?
      end
    }
  end
  
end