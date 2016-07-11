#!/usr/bin/env ruby

require 'pry'

$config = {
  :prompt => "client > "
}

$env = {
  :empty => {}
}
$envkey = :empty

$indent = "  "

class AnyApiClient
  def hello
    line "hello world"
  end

  def run
    describe
    self.pry
  end

  def describe
    puts  "welcome:"
    puts
    env
    puts
  end

  def line text
    puts "#{$indent}#{text}"
  end

  def env
    line "Environment:"
    delim = "    "
    Dir.glob("./env/*.yaml").each{ |f|
      flag = File.basename(f) == File.basename($envkey.to_s) ? " *":""
      line "#{delim}#{f}#{flag}"
    }
    nil
  end

  def switch env
    unless has_env? env
      line
      line "#  no such environment"
      line "#  need to specifiy file path to $env.yaml"
      line "#  type 'env' to show available envs"
      line
    else
      $envkey = env
    end
  end

  def has_env? name
    names = envs.map {|e| File.basename e }
    names.include? File.basename(name)
  end

  def envs
    Dir.glob("./env/*.yaml")
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

def main env
  cl = AnyApiClient.new
  cl.switch(env) if env
  cl.run
  cl.resume
end

if __FILE__ == $0
  main ARGV.first
end


