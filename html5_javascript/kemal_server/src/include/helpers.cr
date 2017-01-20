require "html"

# and override :)
module HTML

  def self.unescape(string : String) # possibly don't need this anymore dep. on crystal version
    return string unless string.includes? '&'
    charlimit = 0x10ffff

    string.gsub(/&(apos|amp|quot|gt|lt|\#[0-9]+|\#[xX][0-9A-Fa-f]+);/) do |string, _match|
      match = _match[1].dup
      case match
      when "apos" then "'"
      when "amp"  then "&"
      when "quot" then "\""
      when "gt"   then ">"
      when "lt"   then "<"
      when /\A#0*(\d+)\z/
        n = $1.to_i
        if n < charlimit
          n.unsafe_chr
        else
          "&##{$1};"
        end
      when /\A#x([0-9a-f]+)\z/i
        n = $1.to_i(16)
        if n < charlimit
          n.unsafe_chr
        else
          "&#x#{$1};"
        end
      else
        "&#{match};"
      end
    end
  end

  # see https://github.com/crystal-lang/crystal/issues/3233
  # I should be OK "ignoring" javascript since I use JSON anyway now...
  # and attributes? who cares, right? :)
  SUBSTITUTIONS.clear()
  SUBSTITUTIONS.merge({
    '&'      => "&amp;",
    '<'      => "&lt;",
    '>'      => "&gt;",
    '"'      => "&quot;",
    '\''      => "&#x27;",
    '/'      => "&#x2F;"
  })

  def self.escape(string : String)
    string.gsub(SUBSTITUTIONS)
  end

  def self.escape(string : String, io : IO)
    string.each_char do |char|
      io << SUBSTITUTIONS.fetch(char, char)
    end
  end
end

class ::Object
  def in?(container)
    return container.includes?(self)
  end
end

class ::String
  def truncate_with_ellipses
    if size > 99
      self[0..100] + "&#8230;" # :|
    else
      self
    end
  end
end
