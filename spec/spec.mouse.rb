require 'rubygems'
require 'sane'
require_relative '../lib/mouse'

begin
Timeout::timeout(1) {
  Mouse::jitter_forever_in_own_thread.join
}
rescue 
end