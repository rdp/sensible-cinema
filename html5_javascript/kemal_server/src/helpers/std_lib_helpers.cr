# sane for crystal! :)

class ::Object
  def in?(container)
    return container.includes?(self)
  end
end

class ::String
  def truncate_with_ellipses
    target_size = 250
    if size > target_size
      sum = 0
      self.split(" ").select{|word| sum += word.size; sum < target_size}.join(" ") + " &#8230;"
    else
      self
    end
  end
end


require "html"

# and override...I tried replacing this since it shouldn't be necessary but then db style sanitized started being not escaped huh?
module HTML

  # see https://github.com/crystal-lang/crystal/issues/3233 crystal is too aggressive [?!]
  # I should be OK "ignoring" javascript since I use JSON anyway now...
  # and attributes? who cares, right? :)
  SUBSTITUTIONS.clear()
  SUBSTITUTIONS.merge!({
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

