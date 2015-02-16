#!/bin/env ruby
# -*- coding: utf-8 -*-
#
# Monitoring Script for MYSQL InnoDB Row Operations
#
# example)
# $ ruby check_mysql_innodb_row_operations.rb -H localhost -u username -p xxxx -o reads -w 100000 -c 200000
# OK - reads 12345 Operations per second|OPS=12345
#
# Auter: Takeshi Yako
# Licence: MIT
# 

require 'rubygems'
require 'optparse'
require 'mysql2'
require 'time'
require 'json'

# Get options

hostname = "#{ARGV[0]}"
port = "#{ARGV[1]}"
username = "#{ARGV[2]}"
password = "#{ARGV[3]}"
warning = "#{ARGV[4]}".to_i
critical = "#{ARGV[5]}".to_i
operation = "#{ARGV[6]}"

options = {}
OptionParser.new do |opt|
  opt.banner = "Usage: #{$0} command <options>"
  opt.separator ""
  opt.separator "Nagios options:"
  opt.on("-H", "--hostname ADDRESS", "Host name or IP Address") { |hostname| options[:hostname] = hostname }
  opt.on("-P", "--port INTEGER", "Port number (default: 3306)") { |port| options[:port] = port }
  opt.on("-u", "--username STRING", "Connect using the indicated username") { |username| options[:username] = username}
  opt.on("-p", "--password STRING", "Use the indicated password to authenticate the connection") { |password| options[:password] = password}
  opt.on("-w", "--warning WARNING", "Nagios warning level. warning >= Current operations/sec") { |warning| options[:warning] = warning.to_i }
  opt.on("-c", "--critical CRITICAL", "Nagios critical level. critical >= Current operations/sec") { |critical| options[:critical] = critical.to_i }
  opt.on("-o", "--operation STRING", "Choice operation. Default is reads. inserts | updates | deletes | reads") { |operation| options[:operation] = operation}
  opt.on_tail("-h", "--help", "Show this message") do
    puts opt
    exit 0
  end

  begin
    opt.parse!
  rescue
    puts "Invalid option. \nsee #{opt}"
    exit
  end 

end.parse!

class CheckMysqlInnodbRowOperations

  # tmp file path
  @@tmp_filename = '/tmp/check_mysql_innodb_row_operations.dat'

  def initialize(options)

    # Get last data
    last_data = ''
    if File.exist?(@@tmp_filename)
      json_data = open(@@tmp_filename) do |io|
        last_data = JSON.load(io)
      end
    end

    # Get unix timestamp
    unixtime = Time.now.to_i

    # Get MySQL STATUS of Queries
    client = Mysql2::Client.new(:host => options[:hostname], :username => options[:username], :password => options[:password], :port => options[:port]) 
    status = client.query("SHOW /*!50000 ENGINE*/ INNODB STATUS").each[0]['Status']

    # Parse innodb status
    value = status.scan(/\nNumber of rows inserted (\d+), updated (\d+), deleted (\d+), read (\d+)\n/)[0]
    values = {
      :inserts => value[0],
      :updates => value[1],
      :deletes => value[2],
      :reads => value[3],
      :unixtime => unixtime
    }

    # Save Current Status
    open(@@tmp_filename, 'w') do |io|
      JSON.dump(values , io)
    end

    # If no tmp file
    if last_data["unixtime"] == nil
      puts "OK - Current Status is saved. values:#{values}"
      exit 0
    else
      # Calc fail under one second
      time_variance = unixtime.to_i - last_data["unixtime"].to_i
      if time_variance == 0
        puts "OK - Calculation is failed. Because time variance is under one second. Try again Later."
        exit 0
      else
        # Which operation
        operation = options[:operation]
        operation = 'reads' if operation.nil?
        # Make Operations per second
        ops =  (values[:"#{operation}"].to_i - last_data["#{operation}"].to_i) / time_variance
        # Check
        basec_message = "#{operation} #{ops} Operations per second|OPS=#{ops}"
        if ops >= options[:critical]
          puts "CRITICAL - #{basec_message}"
          exit 2
        elsif ops >= options[:warning]
          puts "WARNING - #{basec_message}"
        else
          puts "OK - #{basec_message}"
        end
      end
    end
  end

end

CheckMysqlInnodbRowOperations.new(options)
