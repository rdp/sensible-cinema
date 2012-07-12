require 'rubygems'
require 'jeweler' # gem
require 'os' # gem

ENV['PATH'] = "C:\\Program Files (x86)\\Git\\cmd;" + ENV['PATH'] # jeweler's git gem hack-work-around...

Jeweler::Tasks.new do |s|
    s.name = "clean-editing-movie-player"
    s.summary = "an movie scene-skipper/bleeper that works by using EDL's on DVD's or files or online players like netflix instant/hulu"
    s.email = "rogerdpack@gmail.com"
    s.homepage = "http://github.com/rdp"
    s.authors = ["Roger Pack"]
    
    # IF CHANGED PUBLISH NEW GEM [and delete pkg dir] :)
    s.add_dependency 'os', '>= 0.9.4'
    s.add_dependency 'sane', '>= 0.25.4'
    s.add_dependency 'rdp-win32screenshot', '= 0.0.9'
    s.add_dependency 'mini_magick', '>= 3.1' # for ocr...
    s.add_dependency 'whichr', '>= 0.3.6'
    s.add_dependency 'rdp-rautomation', '> 0.6.3' # LODO use mainline with its next release, though I can't remember why
    s.add_dependency 'plist' # for mac
    s.add_dependency 'jruby-win32ole' # jruby-complete.jar doesn't include windows specifics...
    s.add_dependency 'ffi' # mouse, etc. needed for windows MRI, probably jruby too [windows]
    s.files.exclude '**/*.exe', '**/*.wav', '**/images/*', 'vendor/*'
    s.add_development_dependency 'hitimes' # now jruby compat!
    s.add_development_dependency 'rspec', '> 2'
    s.add_development_dependency 'jeweler'
    s.add_development_dependency 'rake'
    if ENV['for_gem_release']
      # add as real dependencies for now, as gem install --development is still broken https://github.com/rubygems/rubygems/issues/309
      for gem in s.development_dependencies #['hitimes', 'rspec', 'jeweler', 'rake']
        s.add_dependency gem.name, gem.requirement
     end  
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
     raise 'possibly dont have that gem are you running jruby for sure?' + d.name +  Gem.loaded_specs.select{|name, spec| name}.inspect
   end
   transitive_deps = dependency_spec.runtime_dependencies
   new_dependencies << transitive_deps
  }
  new_dependencies.flatten.uniq
end

desc 'clear_and_copy_vendor_cache'
task 'clear_and_copy_vendor_cache' do
   FileUtils.rm_rf "../cache.bak"
   system("cp -r vendor/cache ../cache.bak") # so we can retrieve it back later
   Dir['vendor/cache/*'].each{|f|
    FileUtils.rm_rf f
    raise 'unable to delete: ' + f if File.exist?(f)
   }
end

def read_spec
 eval File.read('clean-editing-movie-player.gemspec')
end

desc 'install dependency gems'
task 'install_dependency_gems' do
  get_all_dependency_gems.each{|d|
    system("#{OS.ruby_bin} -S gem install #{d.name}")
  }
end

def get_all_dependency_gems
   spec = read_spec
   dependencies = spec.runtime_dependencies
   dependencies = (dependencies + get_transitive_dependencies(dependencies))
   # out own uniq method...gems...sigh...
   out = {}
   dependencies.each{|d| out[d.name] ||= d}
   out.values
end

desc 'collect binary and gem deps for distribution'
task 'rebundle_copy_in_dependencies' do # => 'gemspec' do
   FileUtils.mkdir_p 'vendor/cache'
   gems = get_all_dependency_gems
   Dir.chdir 'vendor/cache' do
     gems.each{|d|
       system("#{OS.ruby_bin} -S gem unpack #{d.name}")
     }
   end
end

desc 'create distro zippable dir'
task 'create_distro_dir' => :gemspec do # depends on gemspec...
  raise 'need rebundle deps first' unless File.directory? 'vendor/cache'
  require 'fileutils'
  spec = read_spec
  dir_out = cur_folder_with_ver + '/clean-editing-movie-player'
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
  p 'created (still need to zip it) ' + dir_out
  FileUtils.rm_rf Dir[dir_out + '/**/{spec}'] # don't need to distribute those..save 3M!
end

def cur_ver
  got = File.read('VERSION').strip
  spec = read_spec
  raise unless got == spec.version.version # better match
  got
end

def cur_folder_with_ver
  spec = read_spec
  spec.name + '-' + cur_ver
end

def delete_now_packaged_dir name
  FileUtils.rm_rf name
end

desc 'create *.zip,tgz'
task 'zip' do
  name = cur_folder_with_ver
  raise 'doesnt exist yet to zip?' + name unless File.directory? name
  if OS.doze?
    raise 'please distro from linux only so we can get mac distros too'
  else
    sys "zip -r #{name}.zip #{name}"
  end
  sys "tar -cvzf #{name}.mac-os-x.tgz #{name}"
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
    name = cur_folder_with_ver + suffix
    if File.exist? name
      p 'copying to ilab ' + name
      sys "scp #{name} rdp@ilab1.cs.byu.edu:~/incoming"
      p 'copying into sf from ilab ' + name
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
  p 'remember to run all the specs!! Have any!'
  require 'os'
  raise 'need jruby' unless OS.jruby?
  raise unless system("git pull")
  raise unless system("git push origin master")
  #Rake::Task["gem_release"].execute
  Rake::Task["zip"].execute
  Rake::Task["deploy"].execute
  Rake::Task["sync_wbo_website"].execute
  system(c = "cp -r ../cache.bak/* vendor/cache")
  system("rm -rf ../cache.bak")
end
