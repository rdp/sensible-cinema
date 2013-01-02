module RAutomation
  module Adapter
    module WinFfi
      class Label < Control
        include WaitHelper
        include Locators

        def value
          Functions.control_value(Functions.control_hwnd(@window.hwnd, @locators))
        end

        def exist?
          @locators[:id].nil? ? super : super && matches_type(Constants::UIA_LABEL_CONTROL_TYPE)
        end

        alias_method :exists?, :exist?

      end
    end
  end
end
