#!/usr/bin/env ruby
#
#   Copyright (C) 2007, 2008, 2010-2012, 2015 Rocky Bernstein <rockyb@rubyforge.net>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
#    02110-1301 USA.
#

# Author::    Rocky Bernstein  (mailto:rockyb@rubyforge.net)
#
# = linecache
# A module to read and cache lines of a Ruby program.

# == SYNOPSIS
#
# The LineCache module allows one to get any line from any file,
# caching lines of the file on first access to the file. Although the
# file may be any file, the common use is when the file is a Ruby
# script since parsing of the file is done to figure out where the
# statement boundaries are.
#
# The routines here may be is useful when a small random sets of lines
# are read from a single file, in particular in a debugger to show
# source lines.
#
#
#  require 'linecache'
#  lines = LineCache::getlines('/tmp/myruby.rb')
#  # The following lines have same effect as the above.
#  $: << '/tmp'
#  Dir.chdir('/tmp') {lines = LineCache::getlines('myruby.rb')
#
#  line = LineCache::getline('/tmp/myruby.rb', 6)
#  # Note lines[6] == line (if /tmp/myruby.rb has 6 lines)
#
#  LineCache::clear_file_cache
#  LineCache::clear_file_cache('/tmp/myruby.rb')
#  LineCache::update_cache   # Check for modifications of all cached files.
#
# Some parts of the interface is derived from the Python module of the
# same name.
#

# Defining SCRIPT_LINES__ causes Ruby to cache the lines of files
# it reads. The key the setting of __FILE__ at the time when Ruby does
# its read. LineCache keeps a separate copy of the lines elsewhere
# and never destroys SCRIPT_LINES__
SCRIPT_LINES__ = {} unless defined? SCRIPT_LINES__

require 'digest/sha1'
require 'set'

require 'linecache/tracelines'
require 'linecache/version'
# require 'ruby-debug' ; Debugger.start

# = module LineCache
# A module to read and cache lines of a Ruby program.
module LineCache
  LineCacheInfo = Struct.new(:stat, :line_numbers, :lines, :path, :sha1) unless
    defined?(LineCacheInfo)

  # The file cache. The key is a name as would be given by Ruby for
  # __FILE__. The value is a LineCacheInfo object.
  @@file_cache = {}
  @@script_cache = {}

  # Used for CodeRay syntax highlighting
  @@ruby_highlighter = nil

  # Maps a string filename (a String) to a key in @@file_cache (a
  # String).
  #
  # One important use of @@file2file_remap is mapping the a full path
  # of a file into the name stored in @@file_cache or given by Ruby's
  # __FILE__. Applications such as those that get input from users,
  # may want canonicalize a file name before looking it up. This map
  # gives a way to do that.
  #
  # Another related use is when a template system is used.  Here we'll
  # probably want to remap not only the file name but also line
  # ranges. Will probably use this for that, but I'm not sure.
  @@file2file_remap = {}
  @@file2file_remap_lines = {}
  @@script2file = {}

  module_function

  def remove_script_temps
    @@script2file.values.each do |filename|
      File.unlink(filename) if File.exist?(filename)
    end
  end
  at_exit { remove_script_temps }


  # Clear the file cache. If no filename is given clear it entirely.
  # if a filename is given, clear just that filename.
  def clear_file_cache(filename=nil)
    if filename
      if @@file_cache[filename]
        @@file_cache.delete(filename)
      end
    else
      @@file_cache = {}
      @@file2file_remap = {}
      @@file2file_remap_lines = {}
    end
  end

  # Remove syntax-formatted lines in the cache. Use this
  # when you change the CodeRay syntax or Token formatting
  # and want to redo how files may have previously been
  # syntax marked.
  def clear_file_format_cache
    @@file_cache.each_pair do |fname, cache_info|
      cache_info.lines.each_pair do |format, lines|
        next if :plain == format
        @@file_cache[fname].lines[format] = nil
      end
    end
  end

  # Remove syntax-formatted lines in the cache. Use this
  # when you change the CodeRay syntax or Token formatting
  # and want to redo how files may have previously been
  # syntax marked.
  def clear_file_format_cache
    @@file_cache.each_pair do |fname, cache_info|
      cache_info.lines.each_pair do |format, lines|
        next if :plain == format
        @@file_cache[fname].lines[format] = nil
      end
    end
  end

  # Clear the script cache entirely.
  def clear_script_cache()
    @@script_cache = {}
  end

  # Return an array of cached file names
  def cached_files()
    @@file_cache.keys
  end

  # Discard cache entries that are out of date. If +filename+ is +nil+
  # all entries in the file cache +@@file_cache+ are checked.
  # If we don't have stat information about a file, which can happen
  # if the file was read from __SCRIPT_LINES but no corresponding file
  # is found, it will be kept. Return a list of invalidated filenames.
  # nil is returned if a filename was given but not found cached.
  def checkcache(filename=nil, opts=false)
    use_script_lines =
      if opts.kind_of?(Hash)
        opts[:use_script_lines]
      else
        opts
      end

    if !filename
      filenames = @@file_cache.keys()
    elsif @@file_cache.member?(filename)
      filenames = [filename]
    else
      return nil
    end

    result = []
    for filename in filenames
      next unless @@file_cache.member?(filename)
      path = @@file_cache[filename].path
      if File.exist?(path)
        cache_info = @@file_cache[filename].stat
        stat = File.stat(path)
        if cache_info
          if stat &&
              (cache_info.size != stat.size or cache_info.mtime != stat.mtime)
            result << filename
            update_cache(filename, opts)
          end
        else
          result << filename
          update_cache(filename, opts)
        end
      end
    end
    return result
  end

  # Cache script if it's not already cached.
  def cache_script(script, opts={})
    if !@@script_cache.member?(script)
      update_script_cache(script, opts)
    end
    script
  end

  # Cache filename if it's not already cached.
  # Return the expanded filename for it in the cache
  # or nil if we can't find the file.
  def cache_file(filename, reload_on_change=false, opts={})
    if @@file_cache.member?(filename)
      checkcache(filename) if reload_on_change
    else
      opts[:use_script_lines] = true
      update_cache(filename, opts)
    end
    if @@file_cache.member?(filename)
      @@file_cache[filename].path
    else
      nil
    end
  end

  # Older routine - for compability.
  # Cache filename if it's not already cached.
  # Return the expanded filename for it in the cache
  # or nil if we can't find the file.
  def cache(filename, reload_on_change=false)
    if @@file_cache.member?(filename)
      checkcache(filename) if reload_on_change
    else
      update_cache(filename, true)
    end
    if @@file_cache.member?(filename)
      @@file_cache[filename].path
    else
      nil
    end
  end

  # Return true if file_or_script is cached
  def cached?(file_or_script)
    if file_or_script.kind_of?(String)
      @@file_cache.member?(unmap_file(file_or_script))
    else
      cached_script?(file_or_script)
    end
  end

  def cached_script?(filename)
    SCRIPT_LINES__.member?(unmap_file(filename))
  end

  def empty?(filename)
    filename=unmap_file(filename)
    !!@@file_cache[filename].lines[:plain]
  end

  # Get line +line_number+ from file named +filename+. Return nil if
  # there was a problem. If a file named filename is not found, the
  # function will look for it in the $: array.
  #
  # Examples:
  #
  #  lines = LineCache::getline('/tmp/myfile.rb')
  #  # Same as above
  #  $: << '/tmp'
  #  lines = LineCache.getlines('myfile.rb')
  #
  def getline(file_or_script, line_number, opts=true)
    reload_on_change =
      if opts.kind_of?(Hash)
        opts[:reload_on_change]
      else
        opts
      end
    lines =
      if file_or_script.kind_of?(String)
        filename = unmap_file(file_or_script)
        filename, line_number = unmap_file_line(filename, line_number)
        getlines(filename, opts)
      else
        script_getlines(file_or_script)
      end
    if lines and (1..lines.size) === line_number
        return lines[line_number-1]
    else
        return nil
    end
  end

  # Read lines of +filename+ and cache the results. However +filename+ was
  # previously cached use the results from the cache. Return nil
  # if we can't get lines
  def getlines(filename, opts=false)
    if opts.kind_of?(Hash)
      reload_on_change, use_script_lines =
        [opts[:reload_on_change], opts[:use_script_lines]]
    else
      reload_on_change, use_script_lines = [opts, false]
      opts = {:reload_on_change => reload_on_change}
    end
    checkcache(filename) if reload_on_change
    format = opts[:output] || :plain
    if @@file_cache.member?(filename)
      lines = @@file_cache[filename].lines
      if opts[:output] && !lines[format]
        lines[format] =
          highlight_string(lines[:plain].join(''), format).split(/\n/)
      end
      return lines[format]
    else
      opts[:use_script_lines] = true
      update_cache(filename, opts)
      if @@file_cache.member?(filename)
        return @@file_cache[filename].lines[format]
      else
        return nil
      end
    end
  end

  def highlight_string(string, output_type)
    require 'rubygems'
    begin
      require 'coderay'
      require 'term/ansicolor'
    rescue LoadError
      return string
    end
    @@ruby_highlighter ||= CodeRay::Duo[:ruby, output_type]
    @@ruby_highlighter.encode(string)
  end

  # Return full filename path for filename
  def path(filename)
    return unless filename.kind_of?(String)
    filename = unmap_file(filename)
    return nil unless @@file_cache.member?(filename)
    @@file_cache[filename].path
  end

  def remap_file(from_file, to_file)
    @@file2file_remap[from_file] = to_file
    cache_file(to_file)
  end

  def remap_file_lines(from_file, to_file, range, start)
    range = (range..range) if range.kind_of?(Fixnum)
    to_file = from_file unless to_file
    if @@file2file_remap_lines[to_file]
      # FIXME: need to check for overwriting ranges: whether
      # they intersect or one encompasses another.
      @@file2file_remap_lines[to_file] << [from_file, range, start]
    else
      @@file2file_remap_lines[to_file]  = [[from_file, range, start]]
    end
  end
  module_function :remap_file_lines

  # Return SHA1 of filename.
  def sha1(filename)
    filename = unmap_file(filename)
    return nil unless @@file_cache.member?(filename)
    return @@file_cache[filename].sha1.hexdigest if
      @@file_cache[filename].sha1
    sha1 = Digest::SHA1.new
    @@file_cache[filename].lines[:plain].each do |line|
      sha1 << line + "\n"
    end
    @@file_cache[filename].sha1 = sha1
    sha1.hexdigest
  end

  # Return the number of lines in filename
  def size(file_or_script)
    cache(file_or_script)
    if file_or_script.kind_of?(String)
      file_or_script = unmap_file(file_or_script)
      return nil unless @@file_cache.member?(file_or_script)
      @@file_cache[file_or_script].lines[:plain].length
    else
      return nil unless @@script_cache.member?(file_or_script)
      @@script_cache[file_or_script].lines[:plain].length
    end
  end

  # Return File.stat in the cache for filename.
  def stat(filename)
    return nil unless @@file_cache.member?(filename)
    @@file_cache[filename].stat
  end
  module_function :stat

  # Return an Array of breakpoints in filename.
  # The list will contain an entry for each distinct line event call
  # so it is possible (and possibly useful) for a line number appear more
  # than once.
  def trace_line_numbers(filename, reload_on_change=false)
    fullname = cache(filename, reload_on_change)
    return nil unless fullname
    e = @@file_cache[filename]
    unless e.line_numbers
      e.line_numbers =
        TraceLineNumbers.lnums_for_str_array(e.lines[:plain])
      e.line_numbers = false unless e.line_numbers
    end
    e.line_numbers
  end

  def unmap_file(file)
    @@file2file_remap[file] ? @@file2file_remap[file] : file
  end
  alias :map_file :unmap_file

  def unmap_file_line(file, line)
    if @@file2file_remap_lines[file]
      @@file2file_remap_lines[file].each do |from_file, range, start|
        if range === line
          from_file = from_file || file
          return [from_file, start+line-range.begin]
        end
      end
    end
    return [file, line]
  end

  # Update a cache entry.  If something is wrong, return nil. Return
  # true if the cache was updated and false if not.
  def update_script_cache(script, opts)
    # return false unless script_is_eval?(script)
    # string = opts[:string] || script.eval_source
    lines = {:plain => string.split(/\n/)}
    lines[opts[:output]] = highlight_string(string, opts[:output]) if
      opts[:output]
    @@script_cache[script] =
      LineCacheInfo.new(nil, nil, lines, nil, opts[:sha1],
                        opts[:compiled_method])
    return true
  end

  # Update a cache entry.  If something's
  # wrong, return nil. Return true if the cache was updated and false
  # if not.  If use_script_lines is true, use that as the source for the
  # lines of the file
  def update_cache(filename, opts=false)
      if opts.kind_of?(Hash)
        use_script_lines = opts[:use_script_lines]
      else
        use_script_lines = opts
        opts = {:use_script_lines => use_script_lines}
      end

    return nil unless filename

    @@file_cache.delete(filename)
    path = File.expand_path(filename)

    if use_script_lines
      list = [filename]
      list << @@file2file_remap[path] if @@file2file_remap[path]
      list.each do |name|
        if !SCRIPT_LINES__[name].nil? && SCRIPT_LINES__[name] != true
          begin
            stat = File.stat(name)
          rescue
            stat = nil
          end
          raw_lines = SCRIPT_LINES__[name]
          lines = {:plain => raw_lines}
          lines[opts[:output]] =
            highlight_string(raw_lines.join, opts[:output]).split(/\n/) if
            opts[:output]
          @@file_cache[filename] = LineCacheInfo.new(stat, nil, lines, path, nil)
          @@file2file_remap[path] = filename
          return true
        end
      end
    end

    if File.exist?(path)
      stat = File.stat(path)
    elsif File.basename(filename) == filename
      # try looking through the search path.
      stat = nil
      for dirname in $:
        path = File.join(dirname, filename)
        if File.exist?(path)
            stat = File.stat(path)
            break
        end
      end
      return false unless stat
    end
    begin
      # (GF) rewind does not work in JRuby with a jar:file:... filename
      # (GF) read file once and only create string if required by opts[:output]
      lines = { :plain => File.readlines(path) }
      if opts[:output]
        lines[opts[:output]] = highlight_string(lines[:plain].join, opts[:output]).split(/\n/)
      end
    rescue
      ##  print '*** cannot open', path, ':', msg
      return nil
    end
    @@file_cache[filename] = LineCacheInfo.new(File.stat(path), nil, lines,
                                               path, nil)
    @@file2file_remap[path] = filename
    return true
  end

end

# example usage
if __FILE__ == $0
  def yes_no(var)
    return var ? "" : "not "
  end

  lines = LineCache::getlines(__FILE__)
  puts "#{__FILE__} has #{LineCache.size(__FILE__)} lines"
  line = LineCache::getline(__FILE__, 6)
  puts "The 6th line is\n#{line}"
  line = LineCache::remap_file(__FILE__, 'another_name')
  puts LineCache::getline('another_name', 7)

  puts("Files cached: #{LineCache::cached_files.inspect}")
  LineCache::update_cache(__FILE__)
  LineCache::checkcache(__FILE__)
  puts "#{__FILE__} has #{LineCache::size(__FILE__)} lines"
  puts "#{__FILE__} trace line numbers:\n" +
    "#{LineCache::trace_line_numbers(__FILE__).to_a.sort.inspect}"
  puts("#{__FILE__} is %scached." %
       yes_no(LineCache::cached?(__FILE__)))
  puts LineCache::stat(__FILE__).inspect
  puts "Full path: #{LineCache::path(__FILE__)}"
  LineCache::checkcache # Check all files in the cache
  LineCache::clear_file_cache
  puts("#{__FILE__} is now %scached." %
       yes_no(LineCache::cached?(__FILE__)))
  digest = SCRIPT_LINES__.select{|k,v| k =~ /digest.rb$/}
  puts digest.first[0] if digest
  line = LineCache::getline(__FILE__, 7)
  puts "The 7th line is\n#{line}"
  LineCache::remap_file_lines(__FILE__, 'test2', (10..20), 6)
  line = LineCache::getline('test2', 11)
  puts "Remapped 11th line of test2 is\n#{line}"
end
