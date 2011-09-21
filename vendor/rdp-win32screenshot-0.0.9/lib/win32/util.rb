module Win32
  class Screenshot
    class Util
      class << self

        def all_desktop_windows
          titles = []
          window_callback = FFI::Function.new(:bool, [ :long, :pointer ], { :convention => :stdcall }) do |hwnd, param|
            titles << [window_title(hwnd), hwnd]
            true
          end

          BitmapMaker.enum_windows(window_callback, nil)
          titles
        end
        
        # just returns a long list of hwnd's...
        # unless with_info is true
        # then it will return all hwnds with full info about each window
        def windows_hierarchy with_info = false          
          all = {}
          desktop_hwnd = BitmapMaker.desktop_window
          root = {:hwnd => desktop_hwnd, :children => []}
          root.merge!(get_info(desktop_hwnd)) if with_info
          parents = []
          parents << root
          window_callback = FFI::Function.new(:bool, [ :long, :pointer ], { :convention => :stdcall }) do |hwnd, param|
            # this is a child of the most recent parent
            myself = {:hwnd => hwnd, :children => []}
            myself.merge!(get_info(hwnd)) if with_info
            parents[-1][:children] << myself
            parents << myself
            if !all[hwnd]
              all[hwnd] = true
              BitmapMaker.enum_child_windows(hwnd, window_callback, nil)
            end
            
            parents.pop
            true
          end
          BitmapMaker.enum_child_windows(desktop_hwnd, window_callback, nil)
          root
        end
        
        def get_info hwnd
          {:title => window_title(hwnd), 
          :class => window_class(hwnd), 
          :dimensions => dimensions_for(hwnd), 
          :starting_coordinates => location_of(hwnd)
          }
        end  
        
        def window_title hwnd
          title_length = BitmapMaker.window_text_length(hwnd) + 1
          title = FFI::MemoryPointer.new :char, title_length
          BitmapMaker.window_text(hwnd, title, title_length)
          title.read_string
        end
        
        def window_class hwnd
          title = FFI::MemoryPointer.new :char, 100
          BitmapMaker.class_name(hwnd, title, 99)
          title.read_string
        end

        def window_hwnd(title_query)
          hwnd = BitmapMaker.hwnd(title_query)
          raise "window with title '#{title_query}' was not found!" unless hwnd
          hwnd
        end
        
        def location_of(hwnd)
          rect = [0, 0, 0, 0].pack('L4')
          BitmapMaker.window_rect(hwnd, rect)
          x, y, width, height = rect.unpack('L4')
          return x, y
        end

        def dimensions_for(hwnd)
          rect = [0, 0, 0, 0].pack('L4')
          BitmapMaker.client_rect(hwnd, rect)
          _, _, width, height = rect.unpack('L4')
          return width, height
        end
        
        def window_process_id(hwnd)
          BitmapMaker.get_process_id_from_hwnd(hwnd)
        end

      end
    end
  end
end