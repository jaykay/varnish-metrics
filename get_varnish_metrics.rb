#!/usr/bin/env ruby
require 'thor'            # used for cli
require 'yaml'            # for parsing yaml
require 'json'            # for parsing json
require 'nokogiri'        # for parsing XML
require 'net/ssh'         # for connecting via ssh

# Extending Integer class for nice formatting
class Integer
  def to_filesize
    {
      'B'  => 1024,
      'KB' => 1024 * 1024,
      'MB' => 1024 * 1024 * 1024,
      'GB' => 1024 * 1024 * 1024 * 1024,
      'TB' => 1024 * 1024 * 1024 * 1024 * 1024
    }.each_pair { |e, s| return "#{(self.to_f / (s / 1024)).round(2)}#{e}" if self < s }
  end
end

# Extending Float for nice formatting
class Float
  def to_formatted_percent
    (self * 100).round(2).to_s + "%"
  end
end

# Formats the output with the given format
def formatted_output(metric, format)
  case format
  when 'text'
    puts "cachesize=" + metric["cachesize"]
    puts "cache_filling=" + metric["cache_filling"]
    puts "cache_hit_rate=" + metric["cache_hit_rate"]
    metric["backends"].each do |backend|
      puts "backend_server_" + backend["name"].gsub("boot.", "") + "=" + backend["state"].downcase
    end
  when 'json'
    puts metric.to_json
  when 'json-pretty'
    puts JSON.pretty_generate(metric)
  when 'yaml'
    puts metric.to_yaml
  when 'xml'
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.metric {
        xml.cachesize metric["cachesize"]
        xml.send("cache-filling", metric["cache_filling"])
        xml.send("cache-hit-rate", metric["cache_hit_rate"])
        xml.backends {
          metric["backends"].each do |backend|
            xml.backend {
              xml.name backend["name"]
              xml.state backend["state"].downcase
            }
          end
        }
      }
    end
    puts builder.to_xml
  else
    STDERR.puts "ERROR: You did not provide a valid output format. Please use some of the following: text\n json\n json-pretty\n yaml\n xml\n \n For help run: $ ./get_varnish_metrics.rb help get_metrics"
  end
end

# when called with --debug some values are printed before the normal output
def debug_output(opts)
  20.times do
    print '-'
  end
  puts "\nDebug:"
  20.times do
    print '-'
  end
  puts "\nOptions:"
  puts opts.inspect
  puts "Metrics:"
  puts @metric.inspect
end

class VarnishMetrics < Thor
  desc "--instance 10.10.10.10 --output text", "Gets metrics of the given instance in the given format"
  option :instance,
    type: :string,
    aliases: '-i',
    banner: '<instance-ip>',
    required: true
  option :output,
    type: :string,
    aliases: '-o',
    banner: '[text|json|json-pretty|yaml|xml]',
    default: 'text'
  option :user,
    type: :string,
    aliases: '-u'
  option :debug,
    type: :boolean
  def get_metrics
    @metric = Hash.new

    begin
      Net::SSH.start(options[:instance], options[:user]) do |ssh|

        # Get size, filling hits and misses of the varnish server
        metrics = ssh.exec!("varnishstat -1 -f MAIN.cache_hit -f MAIN.cache_miss -f SMA.s0.g_space -f SMA.s0.c_bytes | awk '{print $2}'").split("\n")

        @metric["cache_hit_rate"] = metrics[0].to_i.fdiv(metrics[0].to_i + metrics[1].to_i).to_formatted_percent
        @metric["cache_filling"] = metrics[3].to_i.to_filesize
        @metric["cachesize"] = metrics[2].to_i.to_filesize

        # Get backends with status
        backends = ssh.exec!("varnishadm backend.list | awk 'NR>1 {print $1, $3}'").split("\n")
        @metric["backends"] = []
        backends.each do |b|
          backend = { "name" => b.split(" ")[0], "state" => b.split(" ")[1] }
          @metric["backends"] << backend
        end
      end
      debug_output(options) if options[:debug]
      formatted_output(@metric, options[:output])
    rescue Net::SSH::ConnectionTimeout
      STDERR.puts "ERROR: Connection timed out. Did you provide the correct settings?"
    end
  end

  default_task :get_metrics
end

VarnishMetrics.start
