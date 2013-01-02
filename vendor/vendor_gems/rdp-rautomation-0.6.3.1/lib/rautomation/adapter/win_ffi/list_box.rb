module RAutomation
  module Adapter
    module WinFfi

      class ListBox < Control
        include WaitHelper
        include Locators

        def count
          UiaDll::find_children(uia_control(@locators[:id]), nil)
        end

        def items
          list_items = []
          children = FFI::MemoryPointer.new :pointer, self.count
          length = UiaDll::find_children(uia_control(@locators[:id]), children)
          children.read_array_of_pointer(length).each do |child|
            child_name = FFI::MemoryPointer.new :char, UiaDll::get_name(child, nil) + 1
            UiaDll::get_name(child, child_name)
            list_items.push child_name.read_string
          end
          list_items
        end

        def exist?
          @locators[:id].nil? ? super : super && matches_type(Constants::UIA_LIST_CONTROL_TYPE)
        end

        alias_method :exists?, :exist?

        def selected?(index)
          children = FFI::MemoryPointer.new :pointer, self.count
          length = UiaDll::find_children(uia_control(@locators[:id]), children)
          target_element = children.read_array_of_pointer(length)[index]
          is_selected = FFI::MemoryPointer.new :int, 1

          if UiaDll::get_is_selected(target_element, is_selected) == 1
            return is_selected.read_int == 1
          else
            return false
          end
        end

        def select(index)
          children = FFI::MemoryPointer.new :pointer, self.count

          length = UiaDll::find_children(uia_control(@locators[:id]), children)
          target_element = children.read_array_of_pointer(length)[index]

          UiaDll::select(target_element)
        end

        alias_method :strings, :items


      end
    end
  end
end

