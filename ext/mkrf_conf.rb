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
raise 'must be using jruby to be able to run this...at least for now' unless RUBY_PLATFORM =~ /java/

# reset the OCR cache...
require 'rubygems'
require File.dirname(__FILE__) +  '/../lib/ocr'
OCR.clear_cache!

f = File.open(File.join(File.dirname(__FILE__), "Rakefile"), "w") # create dummy rakefile to indicate success
f.write("task :default\n")
f.close