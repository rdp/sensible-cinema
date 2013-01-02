module RAutomation
  module Adapter
    module Autoit
      # @private
      module Locators

        private

        def extract(locators)
          locators = self.class::DEFAULT_LOCATORS.merge(locators) if self.class.const_defined?(:DEFAULT_LOCATORS)
          @locators = locators
          @autoit_locators = "[#{@locators.map do |locator, value|
            locator_key = self.class::LOCATORS[locator] || self.class::LOCATORS[[locator, value.class]]
            value = value.to_i + 1 if locator == :index # use 0-based indexing
            value = value.to_s(16) if locator == :hwnd
            "#{(locator_key || locator)}:#{value}"
          end.join(";")}]"
        end
      end
    end
  end
end
