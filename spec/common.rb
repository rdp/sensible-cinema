require 'rubygems'
begin
  require 'rspec' # rspec2
rescue LoadError
  require 'spec' # rspec1
  require 'spec/autorun'
end

require 'sane'
require_relative '../lib/overlayer'
require 'benchmark'
Thread.abort_on_exception = true
require 'timeout'

begin
  require 'hitimes'
  Benchmark.module_eval {
    def self.realtime
      Hitimes::Interval.measure { yield }
    end
  }
rescue LoadError
  puts 'no hitimes available...'
end

for file in Dir[File.dirname(__FILE__) + "/../lib/*"] do
  # don't load them here in case one or other fails...
  # require file
end
