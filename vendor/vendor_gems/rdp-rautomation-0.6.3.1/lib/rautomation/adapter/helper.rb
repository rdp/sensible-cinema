module RAutomation
  module Adapter
    autoload :Autoit, File.dirname(__FILE__) + "/autoit.rb"
    autoload :WinFfi, File.dirname(__FILE__) + "/win_ffi.rb"

    module Helper
      extend self

      # @private
      # Retrieves default {Adapter} for the current platform.
      def default_adapter
        if ENV['OS'] == 'Windows_NT'
          :win_ffi
        else
          raise "unsupported platform for RAutomation: #{RUBY_PLATFORM}"
        end
      end
    end
  end
end