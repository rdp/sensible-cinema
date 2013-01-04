module RAutomation
  module Adapter
    module WinFfi
      # @private
      module UiaDll
        extend FFI::Library

        ffi_lib File.dirname(__FILE__) + '/../../../../../ext/UiaDll/Release/UiaDll.dll'
        ffi_convention :stdcall

        attach_function :find_window, :RA_FindWindow,
                        [:string], :pointer
        attach_function :is_offscreen, :RA_IsOffscreen,
                        [:pointer], :bool
        attach_function :element_from_handle, :RA_ElementFromHandle,
                        [:long], :pointer
        attach_function :find_child_by_id, :RA_FindChildById,
                        [:pointer, :string], :pointer
        attach_function :current_native_window_handle, :RA_CurrentNativeWindowHandle,
                        [:pointer], :long
        attach_function :set_focus, :RA_SetFocus,
                        [:pointer], :bool
        attach_function :current_control_type, :RA_GetCurrentControlType,
                        [:pointer], :int
        attach_function :find_children, :RA_FindChildren,
                        [:pointer, :pointer], :int
        attach_function :get_name, :RA_GetName,
                        [:pointer, :pointer], :int
        attach_function :get_is_selected, :RA_GetIsSelected,
                        [:pointer, :pointer], :int
        attach_function :select, :RA_Select,
                        [:pointer], :int
      end
    end
  end
end
