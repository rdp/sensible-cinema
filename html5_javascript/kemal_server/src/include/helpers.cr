module HTML
  def self.unescape(string : String)
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
end
