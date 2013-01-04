module RAutomation
  module Adapter
    module WinFfi
      # @private
      module Constants
        WM_GETTEXT = 0xD
        WM_SETTEXT = 0xC
        WM_GETTEXTLENGTH = 0xE
        WM_CLOSE = 0x10

        SW_MAXIMIZE = 3
        SW_MINIMIZE = 6
        SW_RESTORE = 9

        SMTO_ABORTIFHUNG = 0x2

        STANDARD_RIGHTS_REQUIRED = 0xF0000
        SYNCHRONIZE = 0x100000
        PROCESS_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED | SYNCHRONIZE | 0xFFF

        BM_CLICK = 0xF5
        BM_GETSTATE = 0xF2
        BST_CHECKED = 0x1

        # keybd_event constants
        KEYEVENTF_EXTENDEDKEY = 0x1
        KEYEVENTF_KEYUP = 0x2

        VK_BACK = 0x08
        VK_TAB = 0x09
        VK_RETURN = 0x0D
        VK_SPACE = 0x20
        VK_CAPITAL = 0x14
        VK_LEFT = 0x25
        VK_UP = 0x26
        VK_RIGHT = 0x27
        VK_DOWN = 0x28
        VK_SHIFT = 0x10
        VK_LSHIFT = 0xA0
        VK_RSHIFT = 0xA1
        VK_MENU = 0x12
        VK_LMENU = 0xA4
        VK_RMENU = 0xA5
        VK_CONTROL = 0x11
        VK_LCONTROL = 0xA2
        VK_RCONTROL = 0xA3
        VK_ESCAPE = 0x1B
        VK_END = 0x23
        VK_HOME = 0x24
        VK_NUMLOCK = 0x90
        VK_DELETE = 0x2E
        VK_INSERT = 0x2D

        # GetWindow constants
        GW_ENABLEDPOPUP = 6

        # HRESULT
        S_OK = 0

        # IAccessible Button States
        STATE_SYSTEM_UNAVAILABLE = 0x00000001
        STATE_SYSTEM_SELECTED = 0x00000002
        STATE_SYSTEM_FOCUSED = 0x00000004
        STATE_SYSTEM_CHECKED = 0x00000010

        # Combobox
        CB_GETCOUNT = 0x0146
        CB_GETLBTEXTLEN = 0x0149
        CB_GETLBTEXT = 0x0148
        CB_GETCURSEL = 0x0147
        CB_ERR = -1
        CB_SETCURSEL = 0x14E

        # listview
        LVM_FIRST = 0x1000
        LVM_GETITEMCOUNT = LVM_FIRST + 4

        # UI Automation control type IDs
        UIA_LIST_CONTROL_TYPE = 50008
        UIA_LIST_ITEM_CONTROL_TYPE = 50007
        UIA_CHECKBOX_CONTROL_TYPE = 50002
        UIA_BUTTON_CONTROL_TYPE = 50000
        UIA_LABEL_CONTROL_TYPE = 50020
        UIA_RADIO_BUTTON_CONTROL_TYPE = 50013
        UIA_COMBOBOX_CONTROL_TYPE = 50003
        UIA_EDIT_CONTROL_TYPE = 50004
        UIA_HEADER_CONTROL_TYPE = 50034
        UIA_HEADER_ITEM_CONTROL_TYPE	=	50035


      end
    end
  end
end
