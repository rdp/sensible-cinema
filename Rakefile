require 'jeweler'
require 'os'
  Jeweler::Tasks.new do |s|
    s.name = "scene-skipper"
    s.summary = "universal scene skipper (for skipping or muting portions of movie's, basically"
    s.email = "rogerdpack@gmail.com"
    s.homepage = "http://github.com/rdp"
    s.authors = ["Roger Pack"]
    s.add_development_dependency 'rspec'
    s.add_dependency 'sane', '>= 0.22.0'
    s.add_dependency 'rdp-win32screenshot', '>= 0.0.6.2'
    s.extensions = ["ext/mkrf_conf.rb"]
end


task 'spec' do
  success = true
  for file in Dir['spec/*spec*.rb'] do
    p file
    success &= system('cd spec & ' + OS.ruby_bin + " ../" + file)
  end
  p 'success? ' + success.to_s
end