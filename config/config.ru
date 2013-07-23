require "Manager"
require 'sendfile' # that's it! nothing else to do

manager = Manager.new()
app = lambda do |env|
	manager.run( env )
end

run app
