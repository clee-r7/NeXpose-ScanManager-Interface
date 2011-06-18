require File.expand_path(File.join(File.dirname(__FILE__), 'util.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'api-options.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '../../lib/scan_manager.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'print-scan.rb'))
require 'rubygems'
require 'rexml/document'
require 'hirb'
require 'nexpose'

=begin
require 'rubygems'
require 'nexpose'
=end

#------------------------------------------------------------------------------------------------------
# Extends the base API functionality by combining common API commands to produce a simplified
# user command.
#------------------------------------------------------------------------------------------------------
class ExtendedAPI
  attr_accessor :user_name, :password, :host, :nexpose_api, :scan_manager
  @@connected = false
  @verbose = true

  private

    def get_asset_scan_input
      print "Enter the group id:"
      group_id = gets().chomp
      max_scans = Util.get_numeric_input "Enter the max amount of devices to scan (-1 for unlimitted):"

      {:group_id=>group_id, :max_scans=>max_scans}
    end

  public

    def self.is_connected
     @@connected
    end

    def initialize user_name, password, host, verbose
      @user_name = user_name
      @password = password
      @host = host
      @verbose = verbose
      @nexpose_api = Nexpose::Connection.new @host, @user_name, @password
    end

    def threads_running?
      @scan_manager.is_poller_thread_running
    end

    #-------------------------------------------------------------------
    # Logs in to NeXpose and sets a session key on the connector object.
    #-------------------------------------------------------------------
    def do_login
      if not @@connected
        begin
          if @nexpose_api.login
            @@connected = true
          end
        rescue Exception => e
          puts e.message
        end
      end
    end

    #------------------------------------------------------
    # Prints all asset group information in tabular format:
    # | site_id | device_id | address | riskfactor |
    #------------------------------------------------------
    def print_asset_group_info group_id
      group_id = (not group_id || group_id != -1) ? group_id : (Util.get_numeric_input "Enter the group id:")
      group_configs = @nexpose_api.asset_group_config group_id
      puts "\nASSET GROUP INFO (id: #{group_id})"
      puts Hirb::Helpers::AutoTable.render group_configs, :fields => [:site_id, :device_id, :address, :riskfactor]
    rescue Exception => e
      if e.message =~ /Invalid groupID/
        puts 'Group ID does not exist'
      else
        puts e.message
      end
    end

    #----------------------------------------------------------------
    # Prints asset group configuration information in tabular format:
    # | site_id | device_id | address | riskfactor |
    #----------------------------------------------------------------
    def print_asset_groups
      res = @nexpose_api.asset_groups_listing
      puts "\nASSET GROUPS:"
      puts Hirb::Helpers::AutoTable.render res, :fields => [:asset_group_id, :name, :description, :risk_score]
    end

    #----------------------------------------------------------------
    # Starts an asset group scan for a particular group ID
    #
    # group_input: A Hash containing the group_id ie: {group_id => 1}
    #----------------------------------------------------------------
    def start_asset_group_scan group_input
      input = group_input || get_asset_scan_input
      if (not Util.is_number? input[:group_id])
        group_name = input[:group_id].chomp
        res = @nexpose_api.asset_groups_listing

        found = false
        for asset_info in res
          if asset_info[:name].chomp.eql?(group_name)
            input[:group_id] = asset_info[:asset_group_id]
            found = true
            break
          end
        end

        if not found
          raise "Unable to find asset group with name: #{group_name}"
        end

      end

      group_configs = @nexpose_api.asset_group_config input[:group_id]

      # First build a reverse map to ensure we will not be scanning a device more than once.
      device_to_site = {}
      for group_config in group_configs
        key = group_config[:address]
        value = [group_config[:site_id], group_config[:device_id]].flatten
        device_to_site[key] = value;
      end

      # Build a map of site_id->addresses
      site_to_devices = {}
      for address in device_to_site.keys
        key = device_to_site[address][0]
        value = device_to_site[address][1]
        if site_to_devices.has_key? key
          site_to_devices[key] = [site_to_devices[key], value].flatten()
        else
          site_to_devices[key] = [value]
        end
      end

      if input[:max_scans] > 0 and @scan_manager.nil?
        @scan_manager = ScanManager.new @nexpose_api, (not group_input.nil?), 5
      end

      for site in site_to_devices.keys
        if @scan_manager and
						input[:max_scans] > 0

          # If verbose add the print listener to output scan status
          listeners = []

          if @verbose
            @scan_manager.add_observer PrintScanListener.instance
          end

          # Define the conditional scan information needed.
          conditional_scan =
          {
              :site_id   => site.to_i,
              :max_scans => input[:max_scans].to_i,
              :devices   => site_to_devices[site],
              :listeners => listeners
          }

          @scan_manager.add_cond_scan conditional_scan
        else
          res = @nexpose_api.site_device_scan_start site, site_to_devices[site], nil
          if res
            puts "Scan started scan ID: #{res[:scan_id]}, on engine ID: #{res[:engine_id]}"
          else
            put "Scan failed for site #{site}"
          end
        end
      end
    end

    def do_logout
      @nexpose_api.logout
    end

end