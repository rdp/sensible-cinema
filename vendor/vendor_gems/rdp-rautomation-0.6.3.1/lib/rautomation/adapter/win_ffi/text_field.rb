module RAutomation
  module Adapter
    module WinFfi
      class TextField < Control
        include WaitHelper
        include Locators

        # Default locators used for searching text fields.
        DEFAULT_LOCATORS = {:class => /edit/i}

        # @see RAutomation::TextField#set
        def set(text)
          raise "Cannot set value on a disabled text field" if disabled?

          wait_until do
            hwnd = Functions.control_hwnd(@window.hwnd, @locators)
            @window.activate
            @window.active? &&
                    Functions.set_control_focus(hwnd) &&
                    Functions.set_control_text(hwnd, text) &&
                    value == text
          end
        end

        # @see RAutomation::TextField#clear
        def clear
          raise "Cannot set value on a disabled text field" if disabled?
          set ""
        end

        # @see RAutomation::TextField#value
        def value
          Functions.control_value(hwnd)
        end

        # @see RAutomation::TextField#hwnd
        def hwnd
          Functions.control_hwnd(@window.hwnd, @locators)
        end

        def exist?
          @locators[:id].nil? ? super : super && matches_type(Constants::UIA_EDIT_CONTROL_TYPE)
        end

        alias_method :exists?, :exist?



      end
    end
  end
end
