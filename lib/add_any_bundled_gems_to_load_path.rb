=begin
Copyright 2010, Roger Pack 
This file is part of Sensible Cinema.

    Foobar is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Foobar is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
=end

def add_any_bundled_gems_to_load_path
  raise 'no vendor dir?' unless File.directory? 'vendor'
  if File.directory? 'vendor/cache'
    Dir['vendor/cache/**/lib'].each{|lib_dir|
      $: << lib_dir
    }
  else
    require 'rubygems'
    # they'll need imagemagick installed, as well, currently
  end
end

add_any_bundled_gems_to_load_path