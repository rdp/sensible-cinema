
def add_any_bundled_gems_to_load_path
  raise 'no vendor dir?' unless File.directory? 'vendor'
  if File.directory? 'vendor/cache'
    Dir['vendor/cache/**/lib'].each{|lib_dir|
      $: << lib_dir
    }
  else
    require 'rubygems'
    # they'll need imagemagick installed, as well, currently
  end
end

add_any_bundled_gems_to_load_path