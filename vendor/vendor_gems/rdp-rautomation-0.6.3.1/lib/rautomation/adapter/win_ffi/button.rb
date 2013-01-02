module RAutomation
  module Adapter
    module WinFfi
      class Button < Control
        include WaitHelper
        include Locators

        # Default locators used for searching buttons.
        DEFAULT_LOCATORS = {:class => /button/i}

        # @see RAutomation::Button#value
        def value
          Functions.control_value(Functions.control_hwnd(@window.hwnd, @locators))
        end

        def exist?
          @locators[:id].nil? ? super : super && matches_type(Constants::UIA_BUTTON_CONTROL_TYPE)
        end

        alias_method :exists?, :exist?

      end
    end
  end
end
