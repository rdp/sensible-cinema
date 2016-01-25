module RAutomation
  module Adapter
    module WinFfi
      class Radio < Control
        include WaitHelper
        include Locators
        include ButtonHelper


        def exist?
          @locators[:id].nil? ? super : super && matches_type(Constants::UIA_RADIO_BUTTON_CONTROL_TYPE)
        end

        alias_method :exists?, :exist?

      end
    end
  end
end
