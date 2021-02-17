#!/usr/bin/env ruby
#
# This script is a very simple SMTP-daemon, that delivers every incoming email
# to a given schleuder-list. It's meant to help developing without a real,
# local MTA.

require 'socket'
require 'open3'

trap ('INT') { exit 0 }

def usage
  puts "Usage: #{File.basename(__FILE__)} [-p portnum]"
  exit 1
end

# get args
case ARGV.first
when '-h', '--help', 'help'
  usage
when '-p'
  port = ARGV[1].to_i
  if port == 0
    usage
  end
end

port ||= 25
schleuderbin = File.join(File.dirname(__FILE__), 'schleuder')

begin
  # run the server
  server = TCPServer.new('127.0.0.1', port)

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
          puts "New message to #{recipient}"
          err, status = Open3.capture2e("#{schleuderbin} work #{recipient}", {stdin_data: input})
          if status.exitstatus > 0
            puts "Error from schleuder: #{err}."
            connection.puts "550 #{err}"
          else
            connection.puts '250 ok'
          end
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
