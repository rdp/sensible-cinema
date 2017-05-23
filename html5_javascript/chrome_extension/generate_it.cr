require "ecr/macros"
require "io/memory"
require "../kemal_server/src/helpers/subcategories.cr" 
require "html"

# name = "World"

io =  IO::Memory.new
ECR.embed "edited_generic_player.js.ecr", io
File.write("edited_generic_player.js", "//auto-generated file\n" + io.to_s)
