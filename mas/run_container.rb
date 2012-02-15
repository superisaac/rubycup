#!/usr/bin/env ruby
require 'rexml/document'
include REXML
require "mas/mas"
include MAS


def run_container(filename, debug = false)
  doc =Document.new(File.new(filename))
  
  Thread.abort_on_exception = true
  container_port = XPath.first(doc, "/container/attribute::port").to_s.to_i
  container_name =  XPath.first(doc, "/container/attribute::name").to_s
  platform = XPath.first(doc, "/container/attribute::platform").to_s

  if platform != nil and platform.length > 0
    #
    # The container should be attached to a platform instead of being a platform itself
    #
    p = Container.new(container_name, "localhost:#{container_port}", platform.to_s)
  else
    # the container is a platform
    p = Platform.new(container_name, "localhost:#{container_port}")
  end

  s = p.start_service { |p|
    XPath.match(doc, "/container/agents/agent").each { |agent_elem| # agent is an Element object
      agent_name = agent_elem.attributes['name']
      agent_file = agent_elem.attributes['file']
      agent_class = agent_elem.attributes['class']
      arguments = agent_elem.elements['arguments'].get_text.to_s
      if arguments
        arguments = arguments.split
      else
        arguments = []
      end 

      require "#{agent_file}"
      cs = "#{agent_class}.new(agent_name, p, *arguments)"

      if debug
        puts agent_name, agent_file, agent_class, arguments
        puts "Executing #{cs} of file #{agent_file}, #{arguments}"
      end
      p.add_agent(eval(cs))
    }
  }
  s.join
end


def main(argv)
  if argv.size < 1
    container_file = "container.xml"
  else
    container_file = argv[0]
  end
  run_container(container_file)
end

if __FILE__ == $0
  main(ARGV)
end
