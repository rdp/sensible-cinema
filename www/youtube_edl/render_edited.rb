require 'erb'
$template = ERB.new File.read("control_youtube.rhtml")

def render_edited out, incoming_params
    mutes = []
    incoming_params['mute_starts'].each_with_index{|start, idx|
      start = start.to_f
      endy = incoming_params['mute_ends'][idx].to_f
      mutes << "[#{start},#{endy}]"
      out.puts "bad #{endy} < #{start}"  unless endy > start
    }
    out.puts 'mutes:' + mutes.join(',')
    out.puts $template.result(binding)
end
