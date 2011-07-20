require 'ostruct'
require 'optparse'

#------------------------------------------------------------------------------------------------------
# Defines options to be executed against the NeXpose API
#------------------------------------------------------------------------------------------------------
class Options
    def self.parse(args)
      options = OpenStruct.new
      options.verbose = false

      option_parser = OptionParser.new  do |option_parser|
        option_parser.on("-h HOST", "The network address of the NeXpose instance - Required") {|arg| options.host=arg}
        option_parser.on("-u USER", "The user name - Required") {|arg| options.user=arg}
        option_parser.on("-p PASSWORD", "The password - Required") {|arg| options.password=arg}
        option_parser.on("--n1", "List all the asset groups") {|arg| options.key=1}
        option_parser.on("--n2 GI", "List an asset groups config. The GI (group id or group name is required)") do |arg|
          options.key=2
          options.args=arg
        end
        option_parser.on("--ses params", "Start an asset group excluded scan where params are a comma separated list of the site-id to scan followed by
                         asset group id(s) to exclude") do |arg|
          options.key=3
          options.args=arg.chomp
        end
        option_parser.on_tail("--help", "Help") do
          puts option_parser
          exit 0
        end
      end

      begin
       option_parser.parse!(args)
        rescue OptionParser::ParseError => e
            puts "#{e}\n\n#{option_parser}"
            exit 1
      end

      options
    end
end