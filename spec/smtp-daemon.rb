#!/usr/bin/env ruby
#
# This script is a very simple SMTP-daemon, that dumps every incoming email
# into the given directory. It's meant to capture messages from schleuder-lists
# during test-runs.

require 'socket'
require 'open3'

trap ('INT') { exit 0 }

def usage
  puts "Usage: #{File.basename(__FILE__)} portnum output-directory"
  exit 1
end

# get args
if ARGV.first.to_s.match('(-h|--help|help)') || ARGV.empty?
  usage
end

port = ARGV.first.to_i
if port == 0
  usage
end

outputdir = ARGV[1].to_s
if outputdir.empty?
  usage
elsif ! File.directory?(outputdir)
  puts "Not a directory: #{outputdir}"
  exit 1
end

begin
  # run the server
  server = TCPServer.new('localhost', port)

  # receive input
  while (connection = server.accept)
    input = ''
    recipient = ''
    connection.puts '220 localhost SMTP'
    begin
      while line = connection.gets
        line.chomp!
        case line[0..3].downcase
        when 'ehlo', 'helo'
          connection.puts '250 localhost'
        when 'mail', 'rset'
          connection.puts '250 ok'
        when 'rcpt'
          recipient = line.split(':').last.gsub(/[<>\s]*/, '')
          connection.puts '250 ok'
        when 'data'
          connection.puts '354 go ahead'
        when 'quit'
          connection.puts '221 localhost'
        when '.'
          filename = File.join(outputdir, "mail-#{Time.now.to_f}")
          # puts "New message to #{recipient} written to #{filename}"
          IO.write(filename, input)
          connection.puts '250 ok'
        else
          input << line + "\n"
        end
      end
    rescue IOError
    end
    connection.close
  end


rescue => exc
  $stderr.puts exc
  exit 1
end
