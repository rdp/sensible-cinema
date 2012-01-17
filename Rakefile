require 'rubygems'
require 'jeweler' # gem
require 'os' # gem

ENV['PATH'] = "C:\\Program Files (x86)\\Git\\cmd;" + ENV['PATH'] # for jeweler's git gem hackaround...

Jeweler::Tasks.new do |s|
    s.name = "sensible-cinema"
    s.summary = "an EDL scene-skipper/bleeper that works with DVD's and files and online players like netflix instant"
    s.email = "rogerdpack@gmail.com"
    s.homepage = "http://github.com/rdp"
    s.authors = ["Roger Pack"]
    s.add_dependency 'os', '>= 0.9.4'
    s.add_dependency 'sane', '>= 0.25.2'
    s.add_dependency 'rdp-win32screenshot', '= 0.0.9'
    s.add_dependency 'mini_magick', '>= 3.1' # for ocr...
    s.add_dependency 'whichr', '>= 0.3.6'
    s.add_dependency 'rdp-rautomation', '> 0.6.3' # LODO use mainline with next release, though I can't remember why
    s.add_dependency 'rdp-ruby-wmi' # for windows
    s.add_dependency 'plist' # for mac
    s.add_dependency 'jruby-win32ole' # jruby-complete.jar doesn't include windows specifics...
    s.add_dependency 'ffi' # mouse, etc. needed for windows MRI, probably jruby too [windows]
    s.files.exclude '**/*.exe', '**/*.wav', '**/images/*'
    s.add_development_dependency 'hitimes' # now jruby compat!
    s.add_development_dependency 'rspec', '> 2'
    s.add_development_dependency 'jeweler'
    s.add_development_dependency 'rake'
    
    # add as real dependencies for now, as gem install --development is still broken for jruby, basically installing transitive dependencies in error <sigh> (actually might be fixed now though...so we may not need this)

    for gem in s.development_dependencies #['hitimes', 'rspec', 'jeweler', 'rake']
      # bundling rake won't be too expensive, right? and this allows for easier dev setup through gem install
      s.add_dependency gem.name, gem.requirement
    end
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
  new_dependencies.flatten.uniq
end

desc 'clear_and_copy_vendor_cache'
task 'clear_and_copy_vendor_cache' do
   system("rm -rf ../cache.bak")
   system("cp -r vendor/cache ../cache.bak") # for retrieval later
   Dir['vendor/cache/*'].each{|f|
    FileUtils.rm_rf f
    raise 'unable to delete: ' + f if File.exist?(f)
   }
   FileUtils.mkdir_p 'vendor/cache'
end

desc 'collect binary and gem deps for distribution'
task 'rebundle_copy_in_dependencies' => 'gemspec' do
   spec = eval File.read('sensible-cinema.gemspec')
   dependencies = spec.runtime_dependencies
   dependencies = (dependencies + get_transitive_dependencies(dependencies)).uniq
   FileUtils.mkdir_p 'vendor/cache'
   Dir.chdir 'vendor/cache' do
     dependencies.each{|d|
       system("#{OS.ruby_bin} -S gem unpack #{d.name}")
     }
   end
end

desc 'create distro zippable dir'
task 'create_distro_dir' => :gemspec do # depends on gemspec...
  raise 'need rebundle deps first' unless File.directory? 'vendor/cache'
  require 'fileutils'
  spec = eval File.read('sensible-cinema.gemspec')
  dir_out = spec.name + "-" + spec.version.version + '/sensible-cinema'
  old_glob = spec.name + '-*'
  FileUtils.rm_rf Dir[old_glob] # remove any old versions' distro files
  raise 'unable to delete...' if Dir[old_glob].length > 0
  
  existing = Dir['*']
  FileUtils.mkdir_p dir_out
  FileUtils.cp_r(existing, dir_out) # copies files, subdirs in
  # these belong in the parent dir, by themselves.
  root_distro =  "#{dir_out}/.."
  FileUtils.cp_r(dir_out + '/template_bats/mac', root_distro) # the executable bit carries through somehow..
  FileUtils.cp_r(dir_out + '/template_bats/pc', root_distro) # the executable bit carries through somehow..
  FileUtils.cp(dir_out + '/template_bats/RUN SENSIBLE CINEMA CLICK HERE WINDOWS.bat', root_distro)
  FileUtils.cp('template_bats/README_DISTRO.TXT', root_distro)
  p 'created (still need to zips it) ' + dir_out
  FileUtils.rm_rf Dir[dir_out + '/**/{spec}'] # don't need to distribute those..save 3M!
end

def cur_ver
  File.read('VERSION').strip
end

def delete_now_packaged_dir name
  FileUtils.rm_rf name
end

desc 'create *.zip,tgz'
task 'zip' do
  name = 'sensible-cinema-' + cur_ver
  raise 'doesnt exist yet to zip?' unless File.directory? name
  if OS.doze?
    sys "\"c:\\Program Files\\7-Zip\\7z.exe\" a -tzip -r  #{name}.zip #{name}"
  else
    #sys "zip -r #{name}.zip #{name}"
    puts "NOT packaging win installer"
  end
  if OS.doze?
    puts 'NOT packaging OS X installer'
  else
    sys "tar -cvzf #{name}.mac-os-x.tgz #{name}"
  end
  delete_now_packaged_dir name
  p 'created ' + name + '.zip,tgz and also deleted its [create from] folder'
end


def sys arg, failing_is_ok = false
 3.times { |n|
  if n > 0
    p 'retrying ' + arg
  end
  if system arg
    return
  end
 }
 raise arg + ' failed 3x!' unless failing_is_ok
end

desc 'deploy to sourceforge, after zipping'
task 'deploy' do
  p 'creating sf shell'
  sys "ssh rdp@ilab1.cs.byu.edu 'ssh rogerdpack,sensible-cinema@shell.sourceforge.net create'" # needed for the next command to be able to work [weird]
  p 'creating sf dir'
  sys "ssh rdp@ilab1.cs.byu.edu 'ssh rogerdpack,sensible-cinema@shell.sourceforge.net \"mkdir /home/frs/project/s/se/sensible-cinema/#{cur_ver}\"'", true
  for suffix in [ '.zip', '.mac-os-x.tgz']
    name = 'sensible-cinema-' + cur_ver + suffix
    if File.exist? name
      p 'copying to ilab ' + name
      sys "scp #{name} rdp@ilab1.cs.byu.edu:~/incoming"
      p 'copying into sf from ilab'
      sys "ssh rdp@ilab1.cs.byu.edu 'scp ~/incoming/#{name} rogerdpack,sensible-cinema@frs.sourceforge.net:/home/frs/project/s/se/sensible-cinema/#{cur_ver}/#{name}'"
    else
      p 'not copying:' + name
    end
  end
  p 'successfully deployed to sf! ' + cur_ver
end

# task 'gem_release' do
#   FileUtils.rm_rf 'pkg'
#   Rake::Task["build"].execute
#   sys("#{Gem.ruby} -S gem push pkg/sensible-cinema-#{cur_ver}.gem")
#   FileUtils.rm_rf 'pkg'
# end

def on_wbo command
  sys "ssh rdp@ilab1.cs.byu.edu \"ssh wilkboar@rogerdpack.t28.net '#{command}' \""
  
end

desc 'sync wbo website'
task 'sync_wbo_website' do
  on_wbo 'cd ~/sensible-cinema/source && git pull'
end

desc ' (releases with clean cache dir, which we need now)'
task 'full_release' => [:clear_and_copy_vendor_cache, :rebundle_copy_in_dependencies, :create_distro_dir] do # this is :release
  p 'remember to run all the specs first!'
  raise unless system("git pull")
  raise unless system("git push origin master")
  #Rake::Task["gem_release"].execute
  Rake::Task["zip"].execute
  Rake::Task["deploy"].execute
  Rake::Task["sync_wbo_website"].execute
  system(c = "cp -r ../cache.bak/* vendor/cache")
  system("rm -rf ../cache.bak")
end
