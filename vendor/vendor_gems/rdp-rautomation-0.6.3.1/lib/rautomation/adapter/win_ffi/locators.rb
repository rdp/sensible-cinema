module RAutomation
  module Adapter
    module WinFfi
      # @private
      module Locators

        private

        def extract(locators)
          # windows locators
          @hwnd = locators[:hwnd].to_i if locators[:hwnd]
          locators[:pid] = locators[:pid].to_i if locators[:pid]
          locators[:index] = locators[:index].to_i if locators[:index]

          # control locator
          locators = self.class::DEFAULT_LOCATORS.merge(locators) if self.class.const_defined?(:DEFAULT_LOCATORS)
          @locators = locators
        end
      end
    end
  end
end
