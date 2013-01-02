module RAutomation
  module Adapter
    module WinFfi
      class Table < Control
        include WaitHelper
        include Locators

        def strings
          rows = []
          header_columns = []

          raise "Not a list control" unless UiaDll::current_control_type(uia_control(@locators[:id])) == Constants::UIA_LIST_CONTROL_TYPE

          children_count = count_children(uia_control(@locators[:id]))
          children = FFI::MemoryPointer.new :pointer, children_count
          UiaDll::find_children(uia_control(@locators[:id]), children)
          children.read_array_of_pointer(children_count).each do |child|
            grandchildren_count = count_children(child)
            grandchildren = FFI::MemoryPointer.new :pointer, grandchildren_count
            UiaDll::find_children(child, grandchildren)
            grandchildren.read_array_of_pointer(grandchildren_count).each do |grandchild|
              grandchild_name = FFI::MemoryPointer.new :char, UiaDll::get_name(grandchild, nil) + 1
              UiaDll::get_name(grandchild, grandchild_name)
              header_columns.push grandchild_name.read_string
            end

            rows.push header_columns
            header_columns = []
          end

          rows
        end

        def select(row)
          Functions.select_table_row(Window.oleacc_module_handle, Functions.control_hwnd(@window.hwnd, @locators), row)
        end

        def selected?(row)
          state = Functions.get_table_row_state(Window.oleacc_module_handle, Functions.control_hwnd(@window.hwnd, @locators), row)
          state & Constants::STATE_SYSTEM_SELECTED != 0
        end

        def row_count
          UiaDll::find_children(uia_control(@locators[:id]), nil)
        end

        private

        def count_children(element)
          UiaDll::find_children(element, nil)
        end


      end
    end
  end
end
