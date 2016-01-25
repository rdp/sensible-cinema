module RAutomation
  class UnknownElementException < RuntimeError
  end
  class UnknownWindowException < UnknownElementException
  end
  class UnknownButtonException < UnknownElementException
  end
  class UnknownTextFieldException < UnknownElementException
  end

  class Window
    include Adapter::Helper
    extend ElementCollections

    has_many :windows, :buttons, :text_fields

    class << self
      # @return [Windows] all windows. 
      def windows
        Windows.new(nil, {})
      end
    end
    
    # Retrieves all windows with similar locators to the current window.
    # @param locators (see #initialize) 
    # @return [Windows] all windows matching current window's _locators_ if no
    #   explicit locators specified or windows matching the specified _locators_.
    def windows(locators = @window.locators)
      Windows.new(nil, locators)
    end

    # Currently used {Adapter}.
    attr_reader :adapter

    # Creates the window object.
    #
    # Possible window _locators_ may depend of the used platform and adapter, but
    # following examples will use :title, :class and :hwnd.
    #
    # @example Use window with some title:
    #   RAutomation::Window.new(:title => "some title")
    #
    # @example Use window with Regexp title:
    #   RAutomation::Window.new(:title => /some title/i)
    #
    # @example Use window with handle (hwnd):
    #   RAutomation::Window.new(:hwnd => 123456)
    #
    # @example Use multiple locators, every locator will be matched (AND-ed) to the window:
    #   RAutomation::Window.new(:title => "some title", :class => "IEFrame")
    #
    # @note Refer to all possible _locators_ in each {Adapter} documentation.
    #
    # _locators_ may also include a key called :adapter to change default adapter,
    # which is dependent of the platform, to automate windows and their controls.
    #
    # It is also possible to change the default adapter by using environment variable called
    # __RAUTOMATION_ADAPTER__
    #
    # @note This constructor doesn't check for window's existance.
    # @note Only visible windows are supported.
    # @note If given _locators_ include :hwnd then every other possible _locator_ is ignored.
    # @param [Hash] locators locators for the window.
    def initialize(locators)
      @adapter = locators.delete(:adapter) || ENV["RAUTOMATION_ADAPTER"] && ENV["RAUTOMATION_ADAPTER"].to_sym || default_adapter
      @window = Adapter.const_get(normalize(@adapter)).const_get(:Window).new(locators)
    end

    class << self
      # Timeout for waiting until object exists. If the timeout exceeds then an {WaitHelper::TimeoutError} is raised.
      @@wait_timeout = 60

      # Change the timeout to wait before {WaitHelper::TimeoutError} is raised.
      # @param [Fixnum] timeout in seconds.
      def wait_timeout=(timeout)
        @@wait_timeout = timeout
      end

      # Retrieve current timeout in seconds to wait before {WaitHelper::TimeoutError} is raised.
      # @return [Fixnum] timeout in seconds
      def wait_timeout
        @@wait_timeout
      end

    end

    # @return [Fixnum] handle of the window which is used internally for other methods.
    # @raise [UnknownWindowException] if the window doesn't exist.
    def hwnd
      wait_until_present
      @window.hwnd
    end

    # @return [Fixnum] process identifier (PID) of the window.
    # @raise [UnknownWindowException] if the window doesn't exist.
    def pid
      wait_until_present
      @window.pid
    end

    # @return [String] title of the window.
    # @raise [UnknownWindowException] if the window doesn't exist.
    def title
      wait_until_present
      @window.title
    end

    # Activates the Window, e.g. brings it to the top of other windows.
    def activate
      @window.activate
    end

    # Checks if the window is active, e.g. on the top of other windows.
    # @return [Boolean] true if the window is active, false otherwise.
    def active?
      @window.active?
    end

    # Returns visible text of the Window.
    # @return [String] visible text of the window.
    # @raise [UnknownWindowException] if the window doesn't exist.
    def text
      wait_until_present
      @window.text
    end

    # Checks if the window exists (does have to be visible).
    # @return [Boolean] true if the window exists, false otherwise.
    def exists?
      @window.exists?
    end

    alias_method :exist?, :exists?

    # Checks if window is visible.
    # @note Window is also visible, if it is behind other windows or minimized.
    # @return [Boolean] true if window is visible, false otherwise.
    # @raise [UnknownWindowException] if the window doesn't exist.
    def visible?
      wait_until_exists
      @window.visible?
    end

    # Checks if the window exists and is visible.
    # @return [Boolean] true if window exists and is visible, false otherwise
    def present?
      exists? && visible?
    end

    # Maximizes the window.
    # @raise [UnknownWindowException] if the window doesn't exist.
    def maximize
      wait_until_present
      @window.maximize
    end

    # Minimizes the window.
    # @raise [UnknownWindowException] if the window doesn't exist.
    def minimize
      wait_until_present
      @window.minimize
    end

    # Checks if window is minimized.
    # @return [Boolean] true if window is minimized, false otherwise.
    # @raise [UnknownWindowException] if the window doesn't exist.
    def minimized?
      wait_until_present
      @window.minimized?
    end

    # Restores the window size and position.
    # @note If the window is minimized, makes it visible again.
    # @raise [UnknownWindowException] if the window doesn't exist.
    def restore
      wait_until_present
      @window.restore
    end

    # Sends keyboard keys to the window. Refer to specific {Adapter} documentation for all possible values.
    # @raise [UnknownWindowException] if the window doesn't exist.
    def send_keys(keys)
      wait_until_present
      @window.send_keys(keys)
    end

    # Closes the window if it exists.
    def close
      return unless @window.exists?
      @window.close
    end

    # Retrieves {Button} on the window.
    # @note Refer to specific {Adapter} documentation for possible _locator_ parameters.
    # @param [Hash] locators for the {Button}.
    # @raise [UnknownWindowException] if the window doesn't exist.
    def button(locators)
      wait_until_present
      Button.new(@window, locators)
    end

    # Retrieves {TextField} on the window.
    # @note Refer to specific {Adapter} documentation for possible _locators_ parameters.
    # @raise [UnknownWindowException] if the window doesn't exist.
    def text_field(locators)
      wait_until_present
      TextField.new(@window, locators)
    end

    # Allows to execute specific {Adapter} methods not part of the public API.
    def method_missing(name, *args)
      @window.send(name, *args)
    end

    private

    def wait_until_present
      WaitHelper.wait_until {present?}
    rescue WaitHelper::TimeoutError
      raise UnknownWindowException, "Window with locator #{@window.locators.inspect} doesn't exist or is not visible!"
    end

    def wait_until_exists
      WaitHelper.wait_until {exists?}
    rescue WaitHelper::TimeoutError
      raise UnknownWindowException, "Window with locator #{@window.locators.inspect} doesn't exist!"
    end

    def normalize adapter
      adapter.to_s.split("_").map {|word| word.capitalize}.join
    end

  end
end
