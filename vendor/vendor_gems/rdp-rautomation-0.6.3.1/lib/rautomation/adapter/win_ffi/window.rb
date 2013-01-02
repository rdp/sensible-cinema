module RAutomation
  module Adapter
    module WinFfi
      autoload :UiaDll, File.dirname(__FILE__) + "/ms_uia/uia_dll"

      class Window
        include WaitHelper
        include Locators
        extend ElementCollections

        has_many :controls

        class << self
          def oleacc_module_handle
            @oleacc_module_handle ||= begin
                                        oleacc = Functions.load_library "oleacc.dll"
                                        Functions.co_initialize nil                                        
                                        oleacc
                                      end
          end
        end

        # Locators of the window.
        attr_reader :locators

        # Possible locators are :title, :text, :hwnd, :pid, :class and :index.

        # Creates the window object.
        # @note this method is not meant to be accessed directly, but only through {RAutomation::Window#initialize}!
        # @param [Hash] locators for searching the window.
        # @option locators [String, Regexp] :title Title of the window
        # @option locators [String, Regexp] :text Visible text of the window
        # @option locators [String, Regexp] :class Internal class name of the window
        # @option locators [String, Fixnum] :hwnd Window handle in decimal format
        # @option locators [String, Fixnum] :pid Window process ID (PID)
        # @option locators [String, Fixnum] :index 0-based index to specify n-th window if all other criteria match
        #   all other criteria match
        # @see RAutomation::Window#initialize
        def initialize(locators)
          extract(locators)
        end

        # Retrieves handle of the window.
        # @note Searches only for visible windows.
        # @see RAutomation::Window#hwnd
        def hwnd
          @hwnd ||= Functions.window_hwnd(@locators)
        end

        # @see RAutomation::Window#pid
        def pid
          Functions.window_pid(hwnd)
        end

        # @see RAutomation::Window#title
        def title
          Functions.window_title(hwnd)
        end

        # @see RAutomation::Window#activate
        def activate
          return if !exists? || active?
          restore if minimized?
          Functions.activate_window(hwnd)
          sleep 1
        end

        # @see RAutomation::Window#active?
        def active?
          exists? && Functions.foreground_window == hwnd
        end

        # @see RAutomation::Window#text
        def text
          Functions.window_text(hwnd)
        end

        # @see RAutomation::Window#exists?
        def exists?
          result = hwnd && Functions.window_exists(hwnd)
          !!result
        end

        # @see RAutomation::Window#visible?
        def visible?
          Functions.window_visible(hwnd)
        end

        # @see RAutomation::Window#maximize
        def maximize
          Functions.show_window(hwnd, Constants::SW_MAXIMIZE)
          sleep 1
        end

        # @see RAutomation::Window#minimize
        def minimize
          Functions.show_window(hwnd, Constants::SW_MINIMIZE)
          sleep 1
        end

        # @see RAutomation::Window#minimized?
        def minimized?
          Functions.minimized(hwnd)
        end

        # @see RAutomation::Window#restore
        def restore
          Functions.show_window(hwnd, Constants::SW_RESTORE)
          sleep 1
        end

        # Activates the window and sends keys to it.
        #
        # Refer to KeystrokeConverter#convert_special_characters for the special keycodes.
        # @see RAutomation::Window#send_keys
        def send_keys(keys)
          shift_pressed = false
          KeystrokeConverter.convert(keys).each do |key|
            wait_until do
              activate
              active?
            end
            press_key key

            if key == Constants::VK_LSHIFT
              shift_pressed = true
              next
            end

            release_key key

            if shift_pressed
              shift_pressed = false
              release_key Constants::VK_LSHIFT
            end
          end
        end

        # @see RAutomation::Window#close
        def close
          Functions.close_window(hwnd)
        end

        # @see Button#initialize
        # @see RAutomation::Window#button
        def button(locator)
          Button.new(self, locator)
        end

        # @see TextField#initialize
        # @see RAutomation::Window#text_field
        def text_field(locator)
          TextField.new(self, locator)
        end

        def label(locator)
          Label.new(self, locator)
        end

        def control(locator)
          Control.new(self, locator)
        end

        def controls(locator)
          Controls.new(self, locator)
        end

        def list_box(locator)
          ListBox.new(self, locator)
        end

        # Redirects all method calls not part of the public API to the {Functions} directly.
        # @see RAutomation::Window#method_missing
        def method_missing(name, *args)
          Functions.respond_to?(name) ? Functions.send(name, *args) : super
        end

        # extend public API
        RAutomation::Window.class_eval do
          def select_list(locator)
            wait_until_exists
            RAutomation::Adapter::WinFfi::SelectList.new(@window, locator)
          end

          def checkbox(locator)
            wait_until_exists
            RAutomation::Adapter::WinFfi::Checkbox.new(@window, locator)
          end

          def radio(locator)
            wait_until_exists
            RAutomation::Adapter::WinFfi::Radio.new(@window, locator)
          end

          def table(locator)
            wait_until_exists
            RAutomation::Adapter::WinFfi::Table.new(@window, locator)
          end

          # Creates the child window object.
          # @note This is an WinFfi adapter specific method, not part of the public API
          # @example
          #   RAutomation::Window.new(:title => /Windows Internet Explorer/i).
          #     child(:title => /some popup/)
          # @param (see Window#initialize)
          # @return [RAutomation::Window] child window, popup or regular window.
          def child(locators)
            RAutomation::Window.new Functions.child_window_locators(@window.hwnd, locators)
          end
        end

        private

        def press_key key
          Functions.send_key(key, 0, 0, nil)
          sleep 0.01
        end

        def release_key key
          Functions.send_key(key, 0, Constants::KEYEVENTF_KEYUP, nil)
          sleep 0.1
        end
      end
    end
  end
end
