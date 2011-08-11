require 'rautomation'
require_relative 'edl_parser'

class AutoWindowFinder
  
  # when they select a file, it contains a...url say...
  # so look for that url, with "this" child window class [?]
  # so basically, if a browser window is "open" to such and such a url
  # and it is mentioned in a file
  # it should find it
  
  
  def self.search_for_url_match edl_dir
    for file in Dir[edl_dir + '/**/*']
      next unless File.file? file
      hash = EdlParser.parse_file file
      winners = []
      if hash[:url]
        window = RAutomation::Window.new(:title => Regexp.new(hash[:url]))
        if window.exist?
          winners << file
        end
      end
    end
    if winners.length == 1
      winners[0]
    else
      nil
    end
  end
  
end