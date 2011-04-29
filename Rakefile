require 'jeweler'
require 'os'

ENV['PATH'] = "C:\\Program Files (x86)\\Git\\cmd;" + ENV['PATH'] # for jeweler's git gem

Jeweler::Tasks.new do |s|
    s.name = "sensible-cinema"
    s.summary = "an EDL scene-selector/bleeper that works with online players like hulu"
    s.email = "rogerdpack@gmail.com"
    s.homepage = "http://github.com/rdp"
    s.authors = ["Roger Pack"]
    s.add_dependency 'sane', '>= 0.22.0'
    s.add_dependency 'rdp-win32screenshot', '>= 0.0.7.3' # was 0.8.0 ?
    s.add_dependency 'mini_magick', '>= 3.1' # for ocr...
    s.add_dependency 'whichr', '>= 0.3.6'
    s.add_dependency 'jruby-win32ole' # LODO take out ...
    s.add_dependency 'rdp-ruby-wmi'
    s.add_dependency 'ffi' # mouse, etc. needed at least for MRI
    
    s.add_development_dependency 'hitimes' # now jruby compat!
    s.add_development_dependency 'rspec' # prefer rspec 2 these days I guess...
    
    # add as real dependencies for now, as gem install --development is still broken for jruby, basically installing transitive dependencies in error
    for name in ['hitimes', 'rspec', 'jeweler', 'rake']
      # bundling rake won't be too expensive, right?
      s.add_dependency name
    end
    
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

def get_transitive_dependencies dependencies
  new_dependencies = []
  dependencies.each{|d|
   gem d.name # make sure it's loaded so that it'll be in Gem.loaded_specs
   begin
     dependency_spec = Gem.loaded_specs.select{|name, spec| name == d.name}[0][1]
   rescue
     raise 'possibly dont have that gem are you running jruby for sure?' + d.name
   end
   transitive_deps = dependency_spec.runtime_dependencies
   new_dependencies << transitive_deps
  }
  new_dependencies.flatten
end

desc 'collect binary and gem deps for distribution'
task 'bundle_dependencies' => 'gemspec' do
   require 'whichr'
   require 'fileutils'
   require 'net/http'
  
   spec = eval File.read('sensible-cinema.gemspec')
   dependencies = spec.runtime_dependencies
   dependencies = (dependencies + get_transitive_dependencies(dependencies)).uniq
   system("rm -rf ../cache.bak")
   system("cp -r vendor/cache ../cache.bak") # for retrieval later
   Dir['vendor/cache/*'].each{|f|
    unless f =~ /jruby.*jar/ # that one takes too long to download...
      FileUtils.rm_rf f
      raise 'unable to delete: ' + f if File.exist?(f)
    end
   }
   FileUtils.mkdir_p 'vendor/cache'
   Dir.chdir 'vendor/cache' do
     dependencies.each{|d|
       system("#{Gem.ruby} -S gem unpack #{d.name}")
     }
     to_here = "jruby-complete-1.5.5.jar"
     unless File.exist? to_here
       url = "/downloads/1.6.1/jruby-complete-1.6.1.jar"
       puts 'downloading in jruby-complete.jar file '  + url
       # jruby complete .jar file
       Net::HTTP.start("jruby.org.s3.amazonaws.com") { |http|
         resp = http.get(url)
         puts 'copying jruby complete in... '
        open(to_here, "wb") { |file|
           file.write(resp.body)
        }
      }
     end
    
     # create a shunt win32ole file, so that require 'win32ole' will just work.
     # XXXX may no longer need it...
     Dir.mkdir 'lib'
     File.write('lib/win32ole.rb', 'require "jruby-win32ole"')
  
   end # chdir
  
end

desc 'create distro zippable dir'
task 'create_distro_dir' do
  raise 'need  bundle_dependencies first' unless File.directory? 'vendor/cache'
  require 'fileutils'
  spec = eval File.read('sensible-cinema.gemspec')
  dir_out = spec.name + "-" + spec.version.version + '/sensible-cinema'
  FileUtils.rm_rf Dir['sensible-cinema-*'] # remove old versions
  raise 'unable to delete zip' if Dir[spec.name + '-*'].length > 0
  
  existing = Dir['*']
  FileUtils.mkdir_p dir_out
  FileUtils.cp_r(existing, dir_out)
  # this one belongs in the trunk
  FileUtils.cp(Dir["#{dir_out}/*.bat"].reject{|f| f =~ /go.*bat/}, "#{dir_out}/..")
  p 'created (still need to zip it) ' + dir_out
end

def cur_ver
  File.read('VERSION').strip
end
task 'zip' do
  name = 'sensible-cinema-' + cur_ver
  c = "\"c:\\Program Files\\7-Zip\\7z.exe\" a -tzip -r  #{name}.zip #{name}"
  raise unless system("\"c:\\Program Files\\7-Zip\\7z.exe\" a -tzip -r  #{name}.zip #{name}")
  FileUtils.rm_rf name
  p 'created ' + name + '.zip, and deleted its folder'
end

task 'deploy' do
  name = 'sensible-cinema-' + cur_ver + ".zip"
  p 'copying in'
  raise unless system("scp #{name} rdp@ilab1.cs.byu.edu:~/incoming")
  p 'copying over'
  raise unless system("ssh rdp@ilab1.cs.byu.edu \"scp ~/incoming/#{name} wilkboar@freemusicformormons.com:~/www/rogerdpackt28/sensible-cinema/releases\"")
  # ugh ugh ughly
  raise unless system("ssh rdp@ilab1.cs.byu.edu 'ssh wilkboar@freemusicformormons.com \\\"rm \\\\~/www/rogerdpackt28/sensible-cinema/releases/latest-sensible-cinema.zip\\\"'")
  raise unless system("ssh rdp@ilab1.cs.byu.edu 'ssh wilkboar@freemusicformormons.com \\\"ln -s \\~/www/rogerdpackt28/sensible-cinema/releases/#{name} \\\\~/www/rogerdpackt28/sensible-cinema/releases/latest-sensible-cinema.zip\\\"'")
end

desc 'j -S rake bundle_dependencies create_distro_dir ... (releases with clean cache dir, which we need now)'
task 'full_release' => [:bundle_dependencies, :create_distro_dir, :build] do # :release sigh
  raise unless system("git pull")
  raise unless system("git push origin master")
  gems = Dir['pkg/*.gem']
  gems[0..-2].each{|f| File.delete f} # kill old versions...
  system("#{Gem.ruby} -S gem push #{gems[-1]}")
  FileUtils.rm_rf 'pkg'
  Rake::Task["zip"].execute
  Rake::Task["deploy"].execute
  system(c = "cp -r ../cache.bak/* vendor/cache")
end