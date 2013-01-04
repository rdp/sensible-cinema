module RAutomation
  class Button
    # @private
    # This constructor is meant to be accessed only through {Window#button} method.
    def initialize(window, locators)
      @window = window
      @locators = locators
      @button = @window.button(@locators)
    end

    # Performs a click on the button.
    # By default click is considered successful if the button doesn't exist after clicking (e.g. window has closed)
    # @yield [button] optional block specifying successful clicking condition.
    # @yieldparam [Button] button which is being clicked on.
    # @yieldreturn [Boolean] true if clicking on the button is successful, false otherwise.
    # @raise [UnknownButtonException] if the button doesn't exist.
    def click
      wait_until_exists
      if block_given?
        @button.click {yield self}
      else
        @button.click
      end
    end

    # Retrieves the value (text) of the button, usually the visible text.
    # @return [String] the value (text) of the button.
    # @raise [UnknownButtonException] if the button doesn't exist.
    def value
      wait_until_exists
      @button.value
    end

    # Checks if the button exists.
    # @return [Boolean] true if button exists, false otherwise.
    def exists?
      @button.exists?
    end

    alias_method :exist?, :exists?

    # Allows to execute specific {Adapter} methods not part of the public API.
    def method_missing(name, *args)
      @button.send(name, *args)
    end

    private

    def wait_until_exists
      WaitHelper.wait_until {exists?}
    rescue WaitHelper::TimeoutError
      raise UnknownButtonException, "Button #{@locators.inspect} doesn't exist on window #{@window.locators.inspect}!"
    end
  end
end
