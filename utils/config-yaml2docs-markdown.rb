#!/usr/bin/env ruby

filename = ARGV.first
if [nil, '-h', '--help'].include?(filename) || !File.readable?(filename)
  puts "This script tries to re-format a schleuder config file into markdown useful to include into the docs.\nUsage: #{File.basename(__FILE__)} config-file.yml"
  exit 1
end

s = File.read(filename)
in_comment = false
in_setting = false
comment = ''

t = s.each_line.map do |line|
  case line
  when "\n"
    in_comment = false
    if in_setting
      in_setting = false
      comment = ''
      # This ends a default value block
      "```\n\n"
    else
      line
    end
  when /^# /
    s = "#{line.slice(2..-2)} "
    if in_comment
      comment << s
    else
      in_comment = true
      comment = ": #{s}"
    end
    nil
  else
    in_comment = false
    if in_setting
      line
    else
      case line
      when /^([^:]{1,}):\s*(\S+.*)$/ # setting with string value
        "**#{$1.chomp}**\n#{comment}\nDefault value: `#{$2}`\n"
      when /^([^:]+):\s*$/ # setting with block value
        in_setting = true
        "**#{$1.chomp}**\n#{comment}\nDefault value:\n```"
      else
        line
      end
    end
  end
end.compact

puts t
