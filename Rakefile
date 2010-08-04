require 'jeweler'
require 'os'
Jeweler::Tasks.new do |s|
    s.name = "sensible-cinema"
    s.summary = "an EDL scene-selector/bleeper that works with online players like hulu"
    s.email = "rogerdpack@gmail.com"
    s.homepage = "http://github.com/rdp"
    s.authors = ["Roger Pack"]
    s.add_development_dependency 'rspec' # prefer rspec 2 I guess...
    s.add_development_dependency 'jeweler'
    s.add_development_dependency 'rdp-rmagick'
    s.add_dependency 'mini_magick' # ocr
    s.add_development_dependency 'hitimes' # now jruby compat. yea!
    s.add_dependency 'sane', '>= 0.22.0'
    s.add_dependency 'rdp-win32screenshot', '>= 0.0.6.2'
    s.extensions = ["ext/mkrf_conf.rb"]
end

desc 'run all specs'
task 'spec' do
  success = true
  for file in Dir['spec/*spec*.rb'] do
    p file
    if !system('cd spec & ' + OS.ruby_bin + " ../" + file)
      success = false
    end
  end
  if success
    p 'all specs passed!' 
  else
    p 'at least one spec failed!'
  end
    
end