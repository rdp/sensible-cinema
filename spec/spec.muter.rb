require 'rubygems'
require 'sane'
require_relative '../lib/muter'
require_relative 'common'

describe 'manual muter' do
  # functional test
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

end