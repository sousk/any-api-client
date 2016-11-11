#!/usr/bin/env ruby

require 'pry'
require 'yaml'
require 'net/http'
require 'erb'
require 'json'

$config = {
  :prompt => "client > "
}
$indent = ""

# Struct.new("Endpoint", :scheme, :host, :port, :path)


class ERB
  def result_hash hash
    b = binding
    eval hash.collect {|k,v| "#{k} = hash[#{k.inspect}];" }.join, b
    result b
  end
end

def erb template, hash
  ERB.new(File.read(template), nil, '-').result_hash hash
end

class Environment

  def initialize dir
    @names = []
    @sources = {}
    Dir.glob("./#{dir}/env/*.yaml").each {|f|
      name = File.basename f, ".yaml"
      @names.push name
      @sources[name.to_sym] = f
    }
  end

  def has? name
    @names.include? name.to_s
  end

  def ls
    @names.each {|n|
      yield n
    }
  end

  def load name
    sym = name.to_sym
    f = @sources[sym]
    YAML.load_file f
  end
end

class AnyApiClient

  @selected = nil

  def initialize appdir
    @env = Environment.new appdir
    @datadir = File.join appdir, 'payload'
    @saved_vars = {}
  end

  def run
    describe
    # debug
    switch :local
    @dat = load :get_offer_timeline
    self.pry
  end

  def describe
    puts  "welcome:"
    puts
    print_env
    puts
  end

  def list
    files = Dir.glob File.join(@datadir, "*.json")
    files.reject! {|f| File.basename(f) == "base.json"}
    files.map{ |f| File.basename(f, ".json").to_sym }
  end

  def line text
    puts "#{$indent}#{text}"
  end

  def save name, json, update=false
    path = File.join @datadir, "#{name.to_s}.json"
    if File.exists?(path) && ! update
      puts "cannot overwrite existing #{path} without update flag."
      return
    end

    File.open(path, "w+") {|f| f.puts JSON.pretty_generate(json) }
    puts "saved."
  end

  def load name
    dat = File.join @datadir, "#{name.to_s}.json"
    return nil unless File.exists? dat

    dat = erb dat, $v
    JSON.parse dat
  end

  def post dat, verbose=false
    host = $endpoint.host
    if ! $version.nil? && ! $version.empty?
      host = "#{$version}-dot-#{host}"
    end
    conn = Net::HTTP.new host, $endpoint.port
    if $endpoint.scheme == 'https'
      conn.use_ssl = true
    end

    req = Net::HTTP::Post.new $endpoint.request_uri
    req["Content-Type"] = "application/json"
    req["Authorization"] = "Bearer #{$v['access_token']}"
    $headers.each {|k,v|
      req[k] = v
    }
    puts "post: >> #{host}", dat.to_json, "<<" if verbose
    puts req["Authorization"]
    req.body = dat.to_json
    puts "try to request"
    @response = conn.request req
    puts "code: #{@response.code}"
    puts "message: #{@response.message}"
    puts "body:", @response.body if verbose
    if @response.code == 200
      @r = JSON.parse @response.body
    end
    JSON.parse @response.body
  end

  def print_env
    line "environment:"
    @env.ls { |item|
      flag = item == @selected ? " *":""
      line "  #{item}#{flag}"
    }
  end

  def switch name
    unless @env.has? name
      puts "no such env"
      return
    end

    if @selected
      @saved_vars[@selected] = {
        :endpoint => $endpoint,
        :headers => $headers,
        :variables => $v,
      }
    end

    @selected = name

    saved = @saved_vars[name]
    if saved
      $endpoint = saved[:endpoint]
      $v = saved[:variables]
      $version = saved[:version]
    else
      loaded = @env.load name
      $endpoint = URI.parse loaded["endpoint"]
      $headers = loaded["headers"]
      $v = loaded["variables"]
      $version = ""
    end
  end

  def resume
    puts "bye 🍵 "
  end
end

Pry.config.prompt = [
  proc { |t, lv, pry|
    $config[:prompt]
  }
]

def main appdir
  cl = AnyApiClient.new appdir
  cl.run
  cl.resume
end

if __FILE__ == $0
  appdir = ARGV.first
  unless appdir && File.exists?(appdir)
    puts "need to specify application dir"
  else
    main appdir
  end
end


