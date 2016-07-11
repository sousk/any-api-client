require 'pry'

class A
	def hello
		puts "hello world"
	end

	def config c
	end

	def run
		binding.pry
	end
end

config = Object.new

Pry.config.prompt = [
	proc { |t, lv, pry|
		"client:"
	}
]

a = A.new
a.config config
a.run

# binding.pry
puts "resumes here"

