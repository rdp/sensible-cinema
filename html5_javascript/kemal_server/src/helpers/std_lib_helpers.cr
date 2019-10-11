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
