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
        option_parser.on("-v", "Verbose") {options.verbose=true}
        option_parser.on("--n1", "List all the asset groups") {|arg| options.key=1}
        option_parser.on("--n2 GI", "List an asset groups config. The GI (group id or group name is required)") do |arg|
          options.key=2
          options.args=arg
        end
        option_parser.on("--n3 GID", "Start an asset group scan. The GID (group id or group name is required) and max scans (-1 unlimited) ie: my_asset_group,-1") do |arg|
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