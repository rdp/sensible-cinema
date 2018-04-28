require 'rubygems'
begin
  require 'jeweler' # gem
rescue LoadError
  puts 'unfortunately, to bootstrap the rakefile we need the jeweler and os gems, please install them manually first'
  puts '$ gem install jeweler -v 1.7.0 && gem install os'
  exit 1
end

require 'os' # gem

if RUBY_VERSION > '2.2.9' && !OS.jruby?
  puts "MRI needs ruby < 2.3.0 to avoid some SAFE thing, but you'll probably need/want jruby in the end regardless!"
  exit 1
end

# basically, to deploy, for windows run innosetup, manual upload
# for mac, run rake full_release_mac, manual upload

ENV['PATH'] = "C:\\Program Files (x86)\\Git\\cmd;" + ENV['PATH'] # jeweler's git gem hack-work-around...

Jeweler::Tasks.new do |s|
    s.name = "clean-editing-movie-player"
    s.summary = "an movie scene-skipper/bleeper that works by using EDL's on DVD's or files or online players like netflix instant/hulu"
    s.email = "rogerdpack@gmail.com"
    s.homepage = "http://github.com/rdp"
    s.authors = ["Roger Pack"]
    
    s.add_dependency 'os', '>= 0.9.4'
    s.add_dependency 'sane', '>= 0.25.4'
    s.add_dependency 'rdp-win32screenshot', '= 0.0.9'
    s.add_dependency 'mini_magick', '>= 3.1' # for ocr...
    s.add_dependency 'whichr', '>= 0.3.6'
    s.add_dependency 'rdp-ruby-wmi', '> 0.3.1' # windows requirement gem for the simple_gui_creator gem, remove when we "gem depend" on them...
    s.add_dependency 'rdp-rautomation', '> 0.6.3' # LODO use mainline with its next release, though I can't remember why
    s.add_dependency 'plist' # for mac
	s.add_dependency 'json' # online player
    s.add_dependency 'jruby-win32ole' # jruby-complete.jar doesn't include windows specifics...
    s.add_dependency 'ffi' # mouse, etc. needed for windows MRI, probably jruby too [windows]
    s.files.exclude '**/*.exe', '**/*.wav', '**/images/*', 'vendor/*'
    s.add_development_dependency 'hitimes' # now jruby compat!
    s.add_development_dependency 'rspec', '> 2'
    s.add_development_dependency 'jeweler'
    s.add_development_dependency 'rake'
    if ENV['for_gem_release']
      # add as real dependencies for now, as gem install --development is still broken https://github.com/rubygems/rubygems/issues/309
      for gem in s.development_dependencies
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
     dependency_spec = Gem.loaded_specs.select{|name, spec| name == d.name}.to_a[0][1] # sometimes a Hash, sometimes an Array? huh?
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
task 'install_dependency_gems' => :gemspec do
  get_all_dependency_gems(false).each{|d|
    system("#{OS.ruby_bin} -S gem install #{d.name}")
  }
end

def get_all_dependency_gems include_transitive_children=true
   spec = read_spec
   dependencies = spec.runtime_dependencies
   dependencies += spec.development_dependencies
   if include_transitive_children
     dependencies = (dependencies + get_transitive_dependencies(dependencies))
   end
   # our own uniq method...gems...sigh...
   out = {}
   dependencies.each{|d| out[d.name] ||= d}
   out.values
end

desc 'create distro zippable dir [i.e. like "finished product"] though not innosetup per se...'
task 'create_distro_dir' => :gemspec do # depends on gemspec...
  require 'fileutils'
  spec = read_spec
  dir_out = 'pkg/' + cur_folder_with_ver + '/clean-editing-movie-player'
  old_glob = 'pkg/' + spec.name + '-*'
  FileUtils.rm_rf Dir[old_glob] # remove any old versions' distro files
  raise 'unable to delete...' if Dir[old_glob].length > 0
  
  all_local_files = Dir['*'] - ['pkg']
  FileUtils.mkdir_p dir_out
  FileUtils.cp_r(all_local_files, dir_out) # copies files, subdirs in
  # a few belong in the parent dir, by themselves.
  root_distro =  "#{dir_out}/.."
  puts "copying " + dir_out + '/template_bats/mac'
  FileUtils.cp_r(dir_out + '/bin/template_bats/mac', root_distro) # the executable bit carries through...this is for the mac-ers out there...
  #FileUtils.cp(dir_out + '/template_bats/RUN SENSIBLE CINEMA CLICK HERE WINDOWS.bat', root_distro)
  FileUtils.cp('bin/template_bats/README_DISTRO.TXT', root_distro)
  p 'created (still need to mac_zip it) ' + dir_out
  FileUtils.rm_rf Dir[dir_out + '/**/{spec}'] # don't need to distribute those..save 3M, baby!
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

desc 'create mac tgz'
task 'mac_zip' do
  name = cur_folder_with_ver
  raise 'doesnt exist yet to zip?' + name unless File.directory? name
  if OS.doze?
    raise 'please distro from linux-y only so mac distros work...'
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
  raise "please deploy manually to google code (from current dir...)!"
end

# task 'gem_release' do
#   FileUtils.rm_rf 'pkg'
#   Rake::Task["build"].execute
#   sys("#{Gem.ruby} -S gem push pkg/sensible-cinema-#{cur_ver}.gem")
#   FileUtils.rm_rf 'pkg'
# end

def on_wbo command
  sys "ssh rdp@ilab.cs.byu.edu \"ssh wilkboar@rogerdpack.t28.net '#{command}' \""
  
end

desc 'sync wbo website'
task 'sync_wbo_website' do
  on_wbo 'cd ~/sensible-cinema/source && git pull'
end

desc ' warns you that windows is innosetup'
task 'full_release_windows' do
  puts "to full release in windows, run innosetup"
  exit 1
end

desc ' (releases with clean cache dir, which we need now)'
task 'full_release_mac' => [:clear_and_copy_vendor_cache, :create_distro_dir] do # this is :release
  p 'remember to run all the specs!! Have any!'
  require 'os'
  raise 'need jruby' unless OS.jruby?
  raise unless system("git pull")
  raise unless system("git push origin master")
  #Rake::Task["gem_release"].execute
  Rake::Task["mac_zip"].execute
  Rake::Task["sync_wbo_website"].execute
  Rake::Task["deploy"].execute
  system(c = "cp -r ../cache.bak/* vendor/cache")
  system("rm -rf ../cache.bak")
end
