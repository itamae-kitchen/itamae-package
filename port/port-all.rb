#!/usr/bin/env ruby
require 'fileutils'
FileUtils.mkdir_p 'tmp'

ARGV.map do |path|
  m = path.match(/~(.+?)\.tar/)
  dist = m[1]
  Thread.new do
    log = File.join('tmp', "port-#$$-#{File.basename(path)}.log")
    File.open(log, 'w') do |io|
      pid = spawn('ruby', 'port/port.rb', dist, path, out: io, err: io)
      _, status = Process.waitpid2(pid)
      [path, log, status]
    end
  end
end.each do |th|
  p th.value
end

