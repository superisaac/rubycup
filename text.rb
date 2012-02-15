require 'rexml/document'
include REXML
require "mas/mas"
include MAS


def run_platform(filename)
  doc =Document.new(File.new(filename))
  puts XPath.first(doc, "/container/attribute::port").to_s.to_i
  
  Thread.abort_on_exception = true
  container_port = XPath.first(doc, "/container/attribute::port").to_s.to_i
  container_name =  XPath.first(doc, "/container/attribute::name").to_s
  platform = XPath.first(doc, "/container/attribute::platform")

  if platform
    # the container is a platform
    p = Platform.new(container_name, "localhost:#{container_port}")
  else   
    p = Container.new(container_name, platform.to-s, "localhost:#{container_port}")
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
      puts agent_name, agent_file, agent_class, arguments

      require "#{agent_file}"
      cs = "#{agent_class}.new(agent_name, p, *arguments)"
      puts cs
      p.add_agent(eval(cs))
    }
  }
  s.join
end

if __FILE__ == $0
  if ARGV.size < 1
    container_file = "container.xml"
  else
    container_file = ARGV[0]
  end
  run_platform(container_file)
end
