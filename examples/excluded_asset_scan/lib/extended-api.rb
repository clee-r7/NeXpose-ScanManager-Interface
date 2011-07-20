require File.expand_path(File.join(File.dirname(__FILE__), 'util.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'api-options.rb'))
require 'rubygems'
require 'rexml/document'
require 'hirb'
require 'nexpose'

#------------------------------------------------------------------------------------------------------
# Extends the base API functionality by combining common API commands to produce a simplified
# user command.
#------------------------------------------------------------------------------------------------------
class ExtendedAPI
	attr_accessor :user_name, :password, :host, :nexpose_api, :scan_manager
	@@connected = false

	def initialize user_name, password, host
		@user_name = user_name
		@password = password
		@host = host
		@nexpose_api = Nexpose::Connection.new @host, @user_name, @password
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

	#
	#
	#
	def start_excluded_scan scan_info
		# Parse the scan_info object to get site
		# to be scanned and the asset group(s) to exclude
		parsed_string = scan_info.to_s.split ','
		site_id = parsed_string[0]
		unless Util.is_number? site_id
			raise ArgumentError.new 'The site-id must be a number'
		end

		# Get all the device_ids for the site
		device_listing_hash = @nexpose_api.site_device_listing site_id
		device_ids = []
		device_listing_hash.each do |device_listing|
			device_ids << device_listing[:device_id].to_i
		end

		# Get all the devices associated with the group(s)
		device_ids_excluded = []
		parsed_string.delete_at(0)
		parsed_string.each do |group_id|
			group_infos = @nexpose_api.asset_group_config group_id
			group_infos.each do |group_info|
				device_ids_excluded << group_info[:device_id].to_i
			end
		end

		# Remove all the devices in the group
		devices_to_scan = device_ids - device_ids_excluded

		# Hopefully this is not an empty set
		if not devices_to_scan or devices_to_scan.empty?
			raise "There are no devices left to scan after devices in groups: #{parsed_string.inspect} are removed from site: #{site_id}"
		end

		# Start an ad-hoc scan.
		res = @nexpose_api.site_device_scan_start site_id, devices_to_scan, nil
		if res
			puts "Scan started scan ID: #{res[:scan_id]}, on engine ID: #{res[:engine_id]}"
		else
			put "Scan start failed for site #{site}"
		end
	end

	#
	#
	#
	def do_logout
		@nexpose_api.logout
	end

end