require 'sane'
require 'yaml'
require_relative 'ocr'
if OS.doze?
  require_relative 'screen_tracker_windows'
elsif OS.mac? || OS.linux?
  require_relative 'screen_tracker_mac'
else
 raise 'unsupported os as of yet'
end

class ScreenTracker
  
  def self.new_from_yaml yaml, timestamp_callback, status_callback # callback can be nil, is used for timestamp changed stuff
    settings = YAML.load yaml
    return new(settings["name"], settings["x"], settings["y"], settings["width"], 
        settings["height"], settings["use_class_name"], settings["digits"], timestamp_callback, status_callback)
  end

  attr_accessor :hwnd # TODO move to windows only

  # writes out all screen tracking info to various files in the current pwd
  def dump_bmps filename = 'dump.bmp'
    File.binwrite filename, get_bmp
    File.binwrite 'all.' + filename, get_full_bmp
    dump_digits(get_digits_as_bitmaps, 'dump_bmp') if @digits
  end
  
  def dump_digits digits, message
    p "#{message} dumping digits all together to dump no: .#{@dump_digit_count}. (current time: #{Time.now.to_f}) in #{Dir.pwd}"
    for type, bitmap in digits
      File.binwrite type.to_s + '.' + @dump_digit_count.to_s + '.bmp', bitmap    
    end
    File.binwrite @dump_digit_count.to_s + '.all_digits.mrsh', Marshal.dump(digits)
    @dump_digit_count += 1
  end
  
  DIGIT_TYPES = [:hours, :minute_tens, :minute_ones, :second_tens, :second_ones]
  
  def identify_digit bitmap
    OCR.identify_digit(bitmap, @digits)
  end
  
  # we have to wait until the next change, because when we start, it might be half-way through
  # the current second...
  def wait_till_next_change
    original = get_bmp
    time_since_last_screen_change = Time.now
    while(@keep_going) 
      # save away the current time to try and be most accurate...
      time_before_current_scan = Time.now
      current = get_bmp
      if current != original
        if @digits
          got = attempt_to_get_time_from_screen time_before_current_scan
          if got
            @status_callback.update_playing_well_status 'tracking it successfully' 
          else
            @status_callback.update_playing_well_status 'screen location where we anticipate digits is changing, but unable to track digits from it!'
            File.binwrite('original.debug.bmp', original)
            File.binwrite('current.debug.bmp', current)
          end
          return got
        else
          puts 'screen time change only detected... [unexpected]' # unit tests do this still <sigh>
          return
        end
      else
        if(Time.now - time_since_last_screen_change > 2.0)
          # screen hasn't changed/updated at all in a long time
          got_implies_able_to_still_ocr = attempt_to_get_time_from_screen time_before_current_scan
          if got_implies_able_to_still_ocr
            @status_callback.update_playing_well_status 'appears screen is paused but still tracking?'
            return got_implies_able_to_still_ocr
          else
            @status_callback.update_playing_well_status  'screen tracker: warning--unable to track screen time for some reason [perhaps screen obscured or it\'s not playing yet?] and screen is not changing at all, either'
            # also reget window hwnd, just in case that's the problem...(can be with VLC moving from title to title)
            retrain_on_window_loop_forever
            # LODO loop through all available player descriptions to find the right one, or a changed different new one, et al [?]
          end
          time_since_last_screen_change = Time.now
        end
      end
      sleep 0.02
    end
  end
  
  # returns like {:hours => nil, :minutes_tens => raw_bmp, ...^M
  def get_digits_as_bitmaps
    # @digits are like {:hours => [100,5], :minute_tens => [x, width], :minute_ones, :second_tens, :second_ones}
    out = {}
    for type in DIGIT_TYPES
      assert @digits.key?(type)
      if @digits[type]
        x,w = @digits[type]
        if(x < 0)
          x = @max_x + x
        end
        x2 = x + w
        raise 'a digit width can never be negative #{w}' if w <= 0
        y2 = @y2
        width = x2 - x
        height = y2 - @y
        # lodo calculate these only once...
        out[type] = capture_area(@hwnd, x, @y, x2, y2)
      end
    end
    out
  end

  def attempt_to_get_time_from_screen start_time
    out = {}
    # force it to have two matching snapshots in a row, to avoid race conditions grabbing the digits...
    # allow youtube to update (sigh) lodo just for utube
    previous = nil 
    sleep 0.05
    current = get_digits_as_bitmaps
    start = Time.now
    while previous != current
      # don't allow it to loop forever or it will never complain of not finding digits if the screen is not actually showing a movie, for instance
      if (Time.now - start > 2)
        return nil # early failure 
      end
      previous = current
      sleep 0.05
      current = get_digits_as_bitmaps
      # lodo it should probably poll *before* calling this, not here...maybe?
    end
    assert previous == current
    digits = current = previous    
    DIGIT_TYPES.each{|type|
      if digits[type]
        digit = identify_digit(digits[type])
        unless digit
          bitmap = digits[type]
          # unable to identify a digit?
          if $DEBUG || $VERBOSE && (type != :hours)
            @a ||= 1
            @a += 1
            @already_wrote ||= {}
            unless @already_wrote[bitmap]
              p 'unable to identify capture!' + type.to_s + @a.to_s + ' dump:' + @dump_digit_count.to_s
              File.binwrite("bad_digit#{@a}#{type}.bmp", bitmap)
              @already_wrote[bitmap] = true
            end
          end
          if type == :hours
            digit = 0 # this one can fail and that's ok in VLC bottom right
          else
            # early (failure) return
            return nil
          end
        else
          p " got digit #{type} OCR as #{digit} which was captured to dump #{@dump_digit_count - 1} #{Time.now_f}" if $DEBUG
        end
        out[type] = digit
      else
        # there isn't one specified as being on screen, so assume it is always zero (like youtube hour)...
        out[type] = 0
      end
    }
    out = "%d:%d%d:%d%d" % DIGIT_TYPES.map{ |type| out[type] }
    puts '', 'got new screen time ' + out + " (+ tracking delta:" + (Time.now - start_time).to_s  + ")" if $VERBOSE
    return out, Time.now-start_time
  end
  
  @keep_going = true
  
  def shutdown
    @keep_going = false
  end
  attr_accessor :thread
  
  def process_forever_in_thread
    @keep_going = true
    @thread = Thread.new {
      while(@keep_going)
        p 'screen tracker thread'
        out_time, delta = wait_till_next_change
        @timestamp_callback.timestamp_changed out_time, delta
      end
      p 'screen tracker exiting tracking thread'
      @status_callback.update_playing_well_status 'stopped'
    }
  end
  
end
