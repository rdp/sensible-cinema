require 'rubygems'
require 'rspec' # rspec2
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
