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
require File.dirname(__FILE__) + "/common"
require_relative '../lib/muter'

describe 'manual muter' do
  # functional test
  
  3.times {
    Muter.mute!
    puts 'muted'
    sleep 1
    Muter.unmute!
    puts 'unmuted'
    sleep 1
  }
  # these rest *should* be able to pass...
  
  Muter.mute!
  Muter.mute!
  puts 'silence'
  sleep 1
  Muter.unmute!
  puts 'non silence'
  sleep 1
  Muter.unmute!
  puts 'non silence'
  sleep 1
  puts 'single takes'
  p Benchmark.realtime { 1.times{Muter.hit_volume_down_key}}
  puts 'triple takes'
  p Benchmark.realtime { 1.times{Muter.unmute!}} # 0.00023848s
  # seems actually like reasonable speed
  Muter.unmute!
end