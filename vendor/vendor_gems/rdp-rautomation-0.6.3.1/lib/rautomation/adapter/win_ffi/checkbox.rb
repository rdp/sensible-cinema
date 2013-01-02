module RAutomation
  module Adapter
    module WinFfi
      class Checkbox < Control
        include WaitHelper
        include Locators
        include ButtonHelper


        def exist?
          @locators[:id].nil? ? super : super && matches_type(Constants::UIA_CHECKBOX_CONTROL_TYPE)
        end

        alias_method :exists?, :exist?

      end
    end
  end
end
