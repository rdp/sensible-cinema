The LineCache module allows one to get any line from any file, caching
the lines and file information on first access to the file. Although
the file may be any file, the common use is when the file is a Ruby
script since parsing of the file is done to figure out where the
statement boundaries are, and we also cache syntax formatting.

The routines here may be is useful when a small random sets of lines
are read from a single file, in particular in a debugger to show
source lines.

*Example*:

```ruby
    require 'linecache'
    lines = LineCache::getlines('/tmp/myruby.rb')
    # The following lines have same effect as the above.
    $: << '/tmp'
    Dir.chdir('/tmp') {lines = LineCache::getlines('myruby.rb')

    line = LineCache::getline('/tmp/myruby.rb', 6)
    # Note lines[6] == line (if /tmp/myruby.rb has 6 lines)

    LineCache::clear_file_cache
    LineCache::clear_file_cache('/tmp/myruby.rb')
    LineCache::update_cache   # Check for modifications of all cached files.
```

The master branch handles *ruby-1.8* and *jruby*.

Use git branches *ruby-1.9* and *ruby-2.1* for code for those respective
Ruby versions. However a patched version of Ruby is needed for this to work. The patches sources are [here](https://sourceforge.net/projects/ruby-debugger-runtime/). For 1.9 and 2.x versions that don't require patched ruby see
https://rubygems.org/search?utf8=%E2%9C%93&query=linecache

I'm sorry there are so many branches and forks of essentially the same thing.
