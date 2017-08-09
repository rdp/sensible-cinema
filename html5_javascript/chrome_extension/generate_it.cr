require "ecr/macros"
require "io/memory"
require "../kemal_server/src/helpers/subcategories.cr" 
require "html"

io =  IO::Memory.new
ECR.embed "edited_generic_player.ecr.js", io
File.write("edited_generic_player.js", "//auto-generated file\n" + io.to_s)
File.write("../kemal_server/public/plugin_javascript/edited_generic_player.js", "//auto-generated file\n" + io.to_s)
