require_relative 'overlayer'

class MplayerEdl
  def self.convert_to_edl specs
    out = ""
    for type, metric in {"mutes" => 1, "blank_outs" => 0}
      specs[type].each{|start, endy, other|
      out += "#{OverLayer.translate_string_to_seconds start} #{OverLayer.translate_string_to_seconds endy} #{metric}\n"
    }
    end
    out
    
  end
end