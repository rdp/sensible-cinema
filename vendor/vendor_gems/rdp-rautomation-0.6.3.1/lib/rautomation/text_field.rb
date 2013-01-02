module RAutomation
  class TextField
    # @private
    # This constructor is meant to be accessed only through {Window#text_field} method.
    def initialize(window, locators) #:nodoc:
      @window = window
      @locators = locators
      @text_field = @window.text_field(@locators)
    end

    # Sets text of the text field.
    # @param [String] text of the field to set.
    # @raise [UnknownTextFieldException] if the text field doesn't exist.
    def set(text)
      wait_until_exists
      @text_field.set(text)
    end

    # Clears text field's text.
    # @raise [UnknownTextFieldException] if the text field doesn't exist.
    def clear
      wait_until_exists
      @text_field.clear
    end

    # Returns text field's current value (text).
    # @return [String] the value (text) of the text field.
    # @raise [UnknownTextFieldException] if the text field doesn't exist.
    def value
      wait_until_exists
      @text_field.value
    end

    # Checks if the text field exists.
    # @return [Boolean] true if text field exists, false otherwise.
    def exists?
      @text_field.exists?
    end

    def hwnd
      wait_until_exists
      @text_field.hwnd
    end

    alias_method :exist?, :exists?

    # Allows to execute specific {Adapter} methods not part of the public API.
    def method_missing(name, *args)
      @text_field.send(name, *args)
    end

    private

    def wait_until_exists
      WaitHelper.wait_until {exists?}
    rescue WaitHelper::TimeoutError
      raise UnknownTextFieldException, "Text field #{@locators.inspect} doesn't exist on window #{@window.locators.inspect}!" unless exists?
    end
  end
end
