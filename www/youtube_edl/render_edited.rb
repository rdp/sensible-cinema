require 'erb'
$template = ERB.new File.read("control_youtube.rhtml")

def combine_arrays array1, array2
    array1 ||= []
    array2 ||= []
    raise unless array1.length == array2.length
    out = []
    array1.each_with_index{|start, idx|
      start = translate_string_to_seconds start
      endy = translate_string_to_seconds array2[idx]
      out << "[#{start},#{endy}]"
      raise "bad #{endy} < #{start}"  unless endy > start
    }
    out
end

def render_edited out, incoming_params
    mutes = combine_arrays incoming_params['mute_start'], incoming_params['mute_end']
    splits = combine_arrays incoming_params['skip_start'], incoming_params['skip_end']
    video_id = incoming_params['youtube_video_id'][0]
    should_loop = incoming_params['loop'][0] || '0' # everything's an array, even if not there? weird
    out.puts $template.result(binding)
    # html tag has already been closed...hmm
    out.puts 'mutes: ' + mutes.join(', ') + ' skips: ' + splits.join(', ') + "\n"
end

  def translate_string_to_seconds s
    if s.is_a? Numeric
      return s.to_f # easy out.
    end
    
    s = s.strip
    total = 0.0
    seconds = nil
    seconds = s.split(":")[-1]
    raise 'does not look like a timestamp? ' + seconds.inspect unless seconds =~ /^\d+(|[,.]\d+)$/
    seconds.gsub!(',', '.')
    total += seconds.to_f
    minutes = s.split(":")[-2] || "0"
    total += 60 * minutes.to_i
    hours = s.split(":")[-3] || "0"
    total += 60* 60 * hours.to_i
    total
  end
