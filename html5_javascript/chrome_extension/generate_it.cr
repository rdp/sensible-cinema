require "ecr/macros"
require "io/memory"
require "../kemal_server/src/helpers/subcategories.cr" 
require "html"
require "file_utils"

io =  IO::Memory.new
ECR.embed "edited_generic_player.ecr.js", io
File.write("edited_generic_player.js", "//auto-generated file\n" + io.to_s)
File.write("../kemal_server/public/plugin_javascript/edited_generic_player.js", "//auto-generated file\n" + io.to_s)
# can't easily re-use this file
# as it relies on relative loading the other?
# FileUtils.cp("contentscript.js", "../kemal_server/public/plugin_javascript") # in case changed
