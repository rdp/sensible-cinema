require 'java'

class RubyClip
  import java.awt.datatransfer.StringSelection;
  import java.awt.Toolkit;

  include java.awt.datatransfer.ClipboardOwner
  def self.set_clipboard to_this
    stringSelection = StringSelection.new( to_this.to_s )
    clipboard = Toolkit.getDefaultToolkit().getSystemClipboard()
    clipboard.setContents( stringSelection, self );
  end
  
  def self.lostOwnership(aClipboard, aContents) 
     # ignore...
  end
  
end

if $0 == __FILE__
  RubyClip.set_clipboard "from jruby1"
  puts 'set clipboard contents...'
  RubyClip.set_clipboard "from jruby2"
  RubyClip.set_clipboard "from jruby3"
  STDIN.getc
end
