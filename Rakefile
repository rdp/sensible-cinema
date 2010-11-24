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

desc 'collect gem deps for distribution zip'
task 'bundle_dependencies' => 'gemspec' do
   spec = eval File.read('sensible-cinema.gemspec')
end