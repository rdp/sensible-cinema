require 'jeweler'
require 'os'
Jeweler::Tasks.new do |s|
    s.name = "sensible-cinema"
    s.summary = "an EDL scene-selector/bleeper that works with online players like hulu"
    s.email = "rogerdpack@gmail.com"
    s.homepage = "http://github.com/rdp"
    s.authors = ["Roger Pack"]
    s.add_dependency 'sane', '>= 0.22.0'
    s.add_dependency 'rdp-win32screenshot', '>= 0.0.7.3'
    s.add_dependency 'mini_magick', '>= 3.1' # for ocr...
    s.add_dependency 'whichr'
    s.add_dependency 'jruby-win32ole'
    s.add_dependency 'rdp-ruby-wmi'
    s.add_dependency 'ffi' # mouse, etc.
    s.add_development_dependency 'rspec' # prefer rspec 2 I guess...
    s.add_development_dependency 'jeweler'
    s.add_development_dependency 'hitimes' # now jruby compat!
    s.extensions = ["ext/mkrf_conf.rb"]
end

desc 'run all specs'
task 'spec' do
  failed = []
  Dir.chdir 'spec' do
    for file in Dir['*spec*.rb'] do
      puts "Running " + file
      if !system(OS.ruby_bin + " " + file)
        failed << file
      end
    end
  end
  if failed.length == 0
    p 'all specs passed!' 
  else
    p 'at least one spec failed!', failed
  end
    
end

desc 'collect binary and gem deps for distribution'
task 'bundle_dependencies' => 'gemspec' do
   require 'whichr'
   require 'fileutils'
   require 'net/http'
  
   spec = eval File.read('sensible-cinema.gemspec')
   Dir.mkdir 'vendor/cache' rescue nil
   Dir.chdir 'vendor/cache' do
     spec.dependencies.each{|d|
       #system("gem unpack #{d.name}")
      }
     # imagemagick
     Dir.mkdir 'imagemagick' rescue nil
     im_dir = RubyWhich.new.which('identify').select{|dir| dir =~ /ImageMagick/}[0]
     #  "d:\\installs\\ImageMagick-6.6.2-Q16\\identify.EXE",
     Dir["#{File.dirname im_dir}/*"].each{|file|
       FileUtils.cp(file, 'imagemagick') rescue nil
      }
      Dir.mkdir 'jruby' rescue nil
      jruby_dir = RubyWhich.new.which('identify').select{|dir| dir =~ /ImageMagick/}[0]
    
     # jruby.jar file
     Net::HTTP.start("jruby.org.s3.amazonaws.com") { |http|
       resp = http.get("/downloads/1.5.5/jruby-complete-1.5.5.jar")
       open("jruby-complete-1.5.5.jar", "wb") { |file|
         file.write(resp.body)
       }
     }
     
   "/../vendor/cache/imagemagick"
 end
end