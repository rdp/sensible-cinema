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