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

def add_any_bundled_gems_to_load_path
  vendor_dir = File.dirname(__FILE__) +  '/../vendor/vendor_gems'
  raise 'no vendor dir?' unless File.directory?(vendor_dir)
  if File.directory? vendor_dir
    Dir[vendor_dir + '/**/{lib,cli}'].sort.reverse.each{|lib_dir| # sort to prefer newer versioned copies of gems in case I have duplicates locally
      $: << lib_dir
    }
  else
    raise 'should never get here now'
  end
end

add_any_bundled_gems_to_load_path
