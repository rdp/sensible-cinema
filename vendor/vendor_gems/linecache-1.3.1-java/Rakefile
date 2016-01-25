#!/usr/bin/env rake
# -*- Ruby -*-
require 'rubygems'
require 'rubygems/package_task'
require 'rdoc/task'
require 'rake/testtask'

SO_NAME = 'trace_nums.so'

ROOT_DIR = File.dirname(__FILE__)
load File.join %W(#{ROOT_DIR} lib linecache version.rb)

PKG_VERSION = LineCache::VERSION
PKG_NAME           = 'linecache'
PKG_FILE_NAME      = "#{PKG_NAME}-#{PKG_VERSION}"
RUBY_FORGE_PROJECT = 'rocky-hacks'
RUBY_FORGE_USER    = 'rockyb'

FILES = FileList[
  'AUTHORS',
  'COPYING',
  'ChangeLog',
  'NEWS',
  'README.md',
  'Rakefile',
  'ext/linecache/trace_nums.c',
  'ext/linecache/trace_nums.h',
  'ext/linecache/extconf.rb',
  'lib/**/*.rb',
  'test/*.rb',
  'test/data/*.rb',
  'test/short-file'
]

desc 'Test everything'
Rake::TestTask.new(:test) do |t|
  t.libs << 'ext'
  t.pattern = 'test/test-*.rb'
  t.options = '--verbose' if $VERBOSE
end
task :test => :lib

desc 'Create the core ruby-debug shared library extension'
task :lib do
  Dir.chdir('ext/linecache') do
    system("#{Gem.ruby} extconf.rb && make")
  end
end


desc 'Test everything - same as test.'
task :check => :test

desc 'Create a GNU-style ChangeLog via git2cl'
task :ChangeLog do
  system('git log --pretty --numstat --summary | git2cl > ChangeLog')
end

gem_file = nil

# Base GEM Specification
default_spec = Gem::Specification.new do |spec|
  spec.name = 'linecache'

  spec.homepage = 'http://rubyforge.org/projects/rocky-hacks/linecache'
  spec.summary = 'Read file with caching'
  spec.description = <<-EOF
LineCache is a module for reading and caching lines. This may be useful for
example in a debugger where the same lines are shown many times.
EOF

  spec.version = PKG_VERSION

  spec.author = 'R. Bernstein'
  spec.email = 'rockyb@rubyforge.net'
  spec.licenses = ['GPL2']
  spec.platform = Gem::Platform::RUBY
  spec.require_path = 'lib'
  spec.files = FILES.to_a
  spec.extensions = ['ext/linecache/extconf.rb']

  spec.required_ruby_version = '>= 1.8.7'
  spec.date = Time.now

  # rdoc
  spec.has_rdoc = true
  spec.extra_rdoc_files = ['README.md', 'lib/linecache.rb', 'lib/linecache/tracelines.rb']

  spec.test_files = FileList['test/*.rb']
  gem_file = "#{spec.name}-#{spec.version}.gem"

end

# Rake task to build the default package
Gem::PackageTask.new(default_spec) do |pkg|
  pkg.need_tar = true
end

task :default => [:test]

# Windows specification
win_spec = default_spec.clone
win_spec.extensions = []
## win_spec.platform = Gem::Platform::WIN32 # deprecated
win_spec.platform = 'mswin32'
win_spec.files += ["lib/#{SO_NAME}"]

desc 'Create Windows Gem'
task :win32_gem do
  # Copy the win32 extension the top level directory.
  current_dir = File.expand_path(File.dirname(__FILE__))
  source = File.join(current_dir, 'ext', 'win32', SO_NAME)
  target = File.join(current_dir, 'lib', SO_NAME)
  cp(source, target)

  # Create the gem, then move it to pkg.
  Gem::Builder.new(win_spec).build
  gem_file = "#{win_spec.name}-#{win_spec.version}-#{win_spec.platform}.gem"
  mv(gem_file, "pkg/#{gem_file}")

  # Remove win extension from top level directory.
  rm(target)
end

desc 'Remove built files'
task :clean => [:clobber_package, :clobber_rdoc, :rm_patch_residue,
                :rm_tilde_backups] do
  cd 'ext' do
    if File.exists?('Makefile')
      sh 'make clean'
      rm 'Makefile'
    end
    derived_files = Dir.glob('.o') + Dir.glob('*.so')
    rm derived_files unless derived_files.empty?
  end
end

# ---------  RDoc Documentation ------
require 'rdoc/task'
desc "Generate rdoc documentation"
Rake::RDocTask.new("rdoc") do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = "LineCache #{LineCache::VERSION} Documentation"

  # Show source inline with line numbers
  rdoc.options += %w(--inline-source --line-numbers)

  # Make the README.md file the start page for the generated html
  rdoc.options += %w(--main README.md)

  rdoc.rdoc_files.include('lib/*.rb', 'README.md', 'COPYING')
end
desc "Same as rdoc"
task :doc => :rdoc

desc 'Install the gem locally'
task :install => :gem do
  Dir.chdir(ROOT_DIR) do
    sh %{gem install --local pkg/#{gem_file}}
  end
end

namespace :jruby do
  jruby_spec = default_spec.clone
  jruby_spec.platform   = "java"
  jruby_spec.files      = jruby_spec.files.reject {|f| f =~ /^ext/ }
  jruby_spec.extensions = []
  Gem::PackageTask.new(jruby_spec) {}
end
