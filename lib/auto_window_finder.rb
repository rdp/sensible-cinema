require 'rautomation' # might be able to get rid of this...
require_relative 'edl_parser'

class AutoWindowFinder
  
  # when they select a file, it contains a...url say...
  # so look for that url, with "this" child window class [?]
  # so basically, if a browser window is "open" to such and such a url
  # and it is mentioned in a file
  # it should find it
  
  def self.search_for_single_url_match regexp = /Chrome/
    EdlParser.find_single_edit_list_matching(true) {|parsed|
      if url = parsed["url"]
        window = RAutomation::Window.new(:title => regexp)
        if window.exist? 
          if window.text =~ Regexp.new(Regexp.escape url.gsub(/http(s|):\/\//, ""))
            p 'got match' + url
            true
          else
            false
          end
        end
      end
    }
  end
  
  def self.search_for_player_and_url_match player_root_dir
    for filename in Dir[player_root_dir + '/*/*.txt']
      settings = YAML.load_file filename
      if regex = settings["window_title"] # assume regex :)
        p 'searching for player regex', regex
        if search_for_single_url_match regex # applies the regex X url
          return filename
        end
      end
    end
    nil
  end
  
end