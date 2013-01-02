class WIN32OLE_EVENT
  java_import org.racob.com.DispatchEvents

  # Returns OLE event object. The first argument specifies WIN32OLE object. The second argument specifies OLE event name.
  #
  #   ie = WIN32OLE.new('InternetExplorer.Application')
  #   ev = WIN32OLE_EVENT.new(ie, 'DWebBrowserEvents')
  #
  def initialize(ole, event_name=nil)
    @event_handlers = {}

    raise TypeError.new("1st parameter must be WIN32OLE object") if !ole.kind_of? WIN32OLE

    if event_name.nil? # Default event name
      # TODO: get default event
    end

    dispatch = ole.dispatch
    DispatchEvents.new dispatch, RubyInvocationProxy.new(self), dispatch.program_id
  end

  # Defines the callback event. If argument is omitted, this method defines the callback of all events.
  # 
  #  ie = WIN32OLE.new('InternetExplorer.Application')
  #  ev = WIN32OLE_EVENT.new(ie)
  #  ev.on_event("NavigateComplete") {|url| puts url}
  #  ev.on_event() {|ev, *args| puts "#{ev} fired"}
  # 
  def on_event(name=nil, &block)
    if name
      @event_handlers[name.to_s] = block
    else
      @default_handler = block
    end
  end
  
  # removes the callback of event.
  # 
  #   ie = WIN32OLE.new('InternetExplorer.Application')
  #   ev = WIN32OLE_EVENT.new(ie)
  #   ev.on_event('BeforeNavigate2') {|*args|
  #     args.last[6] = true
  #   }
  #     ...
  #   ev.off_event('BeforeNavigate2')
  #     ...
  # 
  def off_event(name=nil)
    if name.nil?
      @event_handlers.clear
      @default_handler = nil
    elsif name.kind_of?(String) || name.kind_of?(Symbol)
      @event_handlers.delete(name.to_s)
    else
      raise TypeError.new("wrong argument type (expected String or Symbol)")
    end
    
    nil
  end

  def method_missing(name, *args)
    name = name.to_s
    handler = @event_handlers[name]
    if handler
      handler.call *args
    elsif @default_handler
      @default_handler.call name, *args
    end
  end

  # Translates and dispatches Windows message.
  #
  # Almost noop this.  We don't because it get CPU hot when people put this
  # in a hot loop!
  def self.message_loop
    DispatchEvents.message_loop
  end
end
