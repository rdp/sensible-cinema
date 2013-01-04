module RAutomation
  module Adapter
    module WinFfi

      class SelectList < Control
        include WaitHelper
        include Locators

        class SelectListOption
          attr_accessor :text, :index, :control_hwnd

          def initialize(select_list, text, index)
            @select_list = select_list
            @text = text
            @index = index
          end

          def selected?
            selected_idx = Functions.send_message(@select_list.control_hwnd, Constants::CB_GETCURSEL, 0, nil)
            return false if selected_idx == Constants::CB_ERR
            @text == Functions.retrieve_combobox_item_text(@select_list.control_hwnd, selected_idx)
          end

          def select
            @select_list.assert_enabled
            Functions.send_message(@select_list.control_hwnd, Constants::CB_SETCURSEL, @index, nil) != Constants::CB_ERR
          end

          alias_method :set, :select
        end

        def initialize(window, locators)
          super
          @hwnd = Functions.control_hwnd(@window.hwnd, @locators)
        end

        def options(options = {})
          items = []

          item_count.times do |item_no|
            item = Functions.retrieve_combobox_item_text(@hwnd, item_no)

            if options[:text] 
              items.push(SelectListOption.new(self, item, item_no)) if options[:text] == item
            else
              items.push(SelectListOption.new(self, item, item_no))
            end
          end

          items
        end

        def value
          selected_option = options.find {|option| option.selected?}
          selected_option ? selected_option.text : ""
        end

        def option(options)
          item_count.times do |item_no|
            item = Functions.retrieve_combobox_item_text(@hwnd, item_no)
            return SelectListOption.new(self, item, item_no) if options[:text] == item
          end

          nil
        end

        def control_hwnd
          @hwnd
        end

        def exist?
          @locators[:id].nil? ? super : super && matches_type(Constants::UIA_COMBOBOX_CONTROL_TYPE)
        end

        alias_method :exists?, :exist?

        private

        def item_count
          Functions.send_message(@hwnd, Constants::CB_GETCOUNT, 0, nil)
        end


      end
    end
  end
end
