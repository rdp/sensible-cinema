require 'erb'
$template = ERB.new File.read("control_youtube.rhtml")

def combine_arrays array1, array2
    array1 ||= []
    array2 ||= []
    raise unless array1.length == array2.length
    out = []
    array1.each_with_index{|start, idx|
      start = start.to_f
      endy = array2[idx].to_f
      out << "[#{start},#{endy}]"
      raise "bad #{endy} < #{start}"  unless endy > start
    }
    out
end


def render_edited out, incoming_params
    mutes = combine_arrays incoming_params['mute_start'], incoming_params['mute_end']
    splits = combine_arrays incoming_params['skip_start'], incoming_params['skip_end']
    video_id =  incoming_params['youtube_video_id'][0]
    out.puts $template.result(binding)
    out.puts 'mutes:' + mutes.join(',') + ' skips:' + splits.join(',')
end
