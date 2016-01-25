module RAutomation
  module Adapter
    module WinFfi
      module ButtonHelper

        def set?
          control_hwnd = Functions.control_hwnd(@window.hwnd, @locators)
          Functions.control_set? control_hwnd
        end

        # @todo call a windows function to do this without clicking
        def clear
          click {!set?} if set?
        end

        # @todo call a windows function to do this without clicking
        def set
          click {set?} unless set?
        end

      end
    end
  end
end
