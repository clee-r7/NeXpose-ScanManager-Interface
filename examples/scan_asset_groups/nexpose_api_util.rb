require File.expand_path(File.join(File.dirname(__FILE__), 'extended-api.rb'))

#------------------------------------------------------------------------------------------------------
# == Synopsis
# Main script to execute specified  API commands against a specified NSC
#
# == Usage
# ruby nexpose_api_util.rb --help
#
# == Author
# Christopher Lee, Rapid7 LLC
#------------------------------------------------------------------------------------------------------

begin

extended_api = nil

if ARGV.length > 0
  $is_command_line = false
  begin
    options = Options.parse ARGV
    extended_api = ::ExtendedAPI.new options.user, options.password, options.host, options.verbose
    extended_api.do_login
    case options.key
      when 1 then extended_api.print_asset_groups
      when 2 then extended_api.print_asset_group_info options.args
      when 3 then
        group_id = options.args.split(',')[0].chomp
        max_scans = options.args.split(',')[1].chomp.to_i
        extended_api.start_asset_group_scan({:group_id => group_id, :max_scans => max_scans})
      else puts "Invalid Input!"
    end

    while extended_api.threads_running?
      # Hold main thread, don't CPU spin
      sleep 5
    end

  rescue Exception => e
    puts e
  end
  exit 0
else
  $is_command_line = true
  # Show Main Commands
  commands =
<<CMDS
  SELECT A COMMAND:
  1 - Print asset groups info
  2 - Print an asset group info
  3 - Scan an asset group
  q - Quit
CMDS

  while !ExtendedAPI.is_connected do
    print "Enter the NeXpose host address:"
    address = gets().chomp()
    print "Enter the user name for this instance:"
    user_name = gets().chomp()
    print "Enter the password for this instance:"
    password = gets().chomp()
    extended_api = ::ExtendedAPI.new user_name, password, address, true
    extended_api.do_login
  end

  input = ''
  while input[0] != 'q' do
    puts "\n\n#{commands}"
    print "\nSelect Option:"
    $global_message = "\nSelect Option:"
    input = gets()
    puts()

    if not ExtendedAPI.is_connected
      extended_api.do_login
    end

    case input[0]
      when '1' then extended_api.print_asset_groups
      when '2' then extended_api.print_asset_group_info nil
      when '3' then extended_api.start_asset_group_scan nil
      else if input[0] != 'q' then puts "Invalid Input!" end
    end
  end

  puts "Bye"

end

ensure
  begin
    if extended_api and ExtendedAPI.is_connected
      extended_api.do_logout
    end
  rescue Nexpose::APIError => e
    # Don't care, maybe session already dead
  end

end