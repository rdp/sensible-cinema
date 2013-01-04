module RAutomation
  module Adapter
    module Autoit
      class Button
        include WaitHelper
        include Locators
        
        # Default locators used for searching buttons.
        DEFAULT_LOCATORS = {:class => /button/i}

        # @private
        # Special-cased locators
        LOCATORS = {
                [:class, Regexp] => :regexpclass,
                :index => :instance,
                :value => :text
        }

        # Creates the button object.
        # @note this method is not meant to be accessed directly, but only through {RAutomation::Window#button}!
        # @param [RAutomation::Window] window this button belongs to.
        # @param [Hash] locators for searching the button.
        # @option locators [String, Regexp] :value Value (text) of the button
        # @option locators [String, Regexp] :class Internal class name of the button
        # @option locators [String, Fixnum] :id Internal ID of the button
        # @option locators [String, Fixnum] :index 0-based index to specify n-th button if all other criteria match
        # @see RAutomation::Window#button
        def initialize(window, locators)
          @window = window
          extract(locators)
        end

        # @see RAutomation::Button#click
        def click
          clicked = false
          wait_until do
            @window.activate
            @window.active? &&
                    Window.autoit.ControlFocus(@window.locator_hwnd, "", @autoit_locators) == 1 &&
                    Window.autoit.ControlClick(@window.locator_hwnd, "", @autoit_locators) == 1 &&
                    clicked = true # is clicked at least once

            block_given? ? yield : clicked && !exists?
          end
        end

        # @see RAutomation::Button#value
        def value
          Window.autoit.ControlGetText(@window.locator_hwnd, "", @autoit_locators)
        end

        # @see RAutomation::Button#exists?
        def exists?
          not Window.autoit.ControlGetHandle(@window.locator_hwnd, "", @autoit_locators).empty?
        end
      end
    end
  end
end
