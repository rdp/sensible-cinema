module RAutomation
  # Waiting with timeout
  module WaitHelper
    extend self
    
    class TimeoutError < StandardError
    end

    # @private
    # Wait until the block evaluates to true or times out.
    def wait_until(timeout = Window.wait_timeout, &block)
      end_time = ::Time.now + timeout

      until ::Time.now > end_time
        result = yield(self)
        return result if result
        sleep 0.5
      end

      raise TimeoutError, "timed out after #{timeout} seconds"
    end
  end
end
