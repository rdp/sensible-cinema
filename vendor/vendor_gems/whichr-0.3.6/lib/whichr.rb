require 'sane'

class RubyWhich
  # search the path for the given names
  # like ['abc'] (in windows, also searches for abc.bat)
  # or ['ab*'] (a glob, in windows, also reveals ab*.bat)
  def which( names, return_non_executables_too = false, realtime_output = false )

    puts "higher in the list is executed first" if realtime_output

    names = Array(names)
    # on doze, you can't pass in * very easily
    # it comes in as \*
    names.map!{|name| name.dup.gsub('\*', '*') } if OS.windows?

    if OS.windows?
      for name in names.dup # avoid recursion
        # windows compat.
        # add .bat, .exe, etc.
        for extension in  ENV['PATHEXT'].split(';') do
          names << name + extension
        end
      end
    end

    all_found = []
    path = ENV['PATH']
    # on windows add cwd
    path += (File::PATH_SEPARATOR + '.') if OS.windows?

    path.split(File::PATH_SEPARATOR).each do |dir|

      for name in names
        if OS.windows?
          names2 = Dir.glob(dir.gsub("\\", "/") + '/' + name.strip)
          unless return_non_executables_too
            names2 = names2.select{|name3| File.executable?(name3) && !File.directory?(name3)} # only real execs for doze
          end
          names2.collect!{|name| File.expand_path(name)} # get the right capitalization
        else
          names2 = Dir.glob(dir + '/' + name.strip)
        end

        # expand paths
        names2.collect!{|name3| File.expand_path(name3).gsub(File::SEPARATOR, File::ALT_SEPARATOR || File::SEPARATOR)}

        # make sure we aren't repeating a previous
        uniques = names2.select{|new|
          new = new.downcase if OS.windows?
          am_unique = true
          all_found.each{|old|
            old = old.downcase if OS.windows?
            if old == new
              am_unique = false
              break
            end
          }
          am_unique
        }

        if realtime_output
          uniques.each{ |file|
            print file

            if !File.executable? file
              print ' (is not executable)'
            end

            if File.directory?(file)
              print ' (is a directory)'
            end
            puts
          }
        end

        all_found += uniques

      end
    end

    if realtime_output
      if all_found == []
        puts 'none found (' + names.inspect + ')'
      end
    end

    all_found
  end

end
