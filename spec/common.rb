require 'rubygems'
begin
  require 'rspec' # rspec2
rescue LoadError
  require 'spec' # rspec1
  require 'spec/autorun'
end

# some useful utilities...

require 'sane'
require 'benchmark'
Thread.abort_on_exception = true
require 'timeout'
require 'fileutils'

begin
  require 'hitimes'
  Benchmark.module_eval {
    def self.realtime
      Hitimes::Interval.measure { yield }
    end
  }
rescue LoadError
  if RUBY_PLATFORM =~ /java/
    require 'java'
    Benchmark.module_eval {
      def self.realtime
        beginy = java.lang.System.nano_time
        yield
        (java.lang.System.nano_time - beginy)/1000000000.0
      end
    }
  else
      puts 'no hitimes available...'
  end
    
end

#for file in Dir[File.dirname(__FILE__) + "/../lib/*"] do
  # don't load them here in case one or other fails...
  # require file
  #end
