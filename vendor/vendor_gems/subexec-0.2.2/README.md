# Subexec
by Peter Kieltyka
http://github/nulayer/subexec

## Description

Subexec is a simple library that spawns an external command with
an optional timeout parameter. It relies on Ruby 1.9's Process.spawn
method. Also, it works with synchronous and asynchronous code.

Useful for libraries that are Ruby wrappers for CLI's. For example,
resizing images with ImageMagick's mogrify command sometimes stalls
and never returns control back to the original process. Enter Subexec.

Tested with MRI 1.9.3, 1.9.2, 1.8.7

Note: Process.spawn seems to be broken with JRuby 1.7.0.dev (as of
April 20th, 2012), and so it uses Process.exec instead.

## Usage

```ruby
sub = Subexec.run "echo 'hello' && sleep 3", :timeout => 5
puts sub.output     # returns: hello
puts sub.exitstatus # returns: 0

sub = Subexec.run "echo 'hello' && sleep 3", :timeout => 1
puts sub.output     # returns: 
puts sub.exitstatus # returns:`
```

## Limitations

Only Ruby 1.9 can spawn non-blocking subprocesses, via Process.spawn.
So Ruby 1.8 support is sheerly for backwards compatibility. 

## Windows Support

Limited Windows support is available. We are more than happy to accept patches.
However, our tests are run on Unix-like operating systems. Primarily, the intended
effect should be that Subexec *works* on Windows, though it may not give
many advantages.
