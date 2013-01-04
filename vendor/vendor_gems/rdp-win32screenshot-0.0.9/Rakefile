# coding: utf-8

require 'rubygems'
require 'rake'
require 'os'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "rdp-win32screenshot"
    gem.summary = %Q{Capture Screenshots on Windows with Ruby}
    gem.description = %Q{Capture Screenshots on Windows with Ruby}
    gem.email = ["jarmo.p@gmail.com", "aslak.hellesoy@gmail.com"]
    gem.homepage = "http://github.com/jarmo/win32screenshot"
    gem.authors = ["Jarmo Pertman", "Aslak Hellesøy"]

    gem.rdoc_options = ["--main", "README.rdoc"]

    gem.add_dependency "ffi"

    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_development_dependency 'os'
    if OS.java?
      gem.add_development_dependency "rmagick4j"
    else
      gem.add_development_dependency "rmagick"
    end
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "Win32::Screenshot #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc "Remove all temporary files"
task :clobber => [:clobber_rdoc, :clobber_rcov] do
  rm_r "spec/tmp"
end