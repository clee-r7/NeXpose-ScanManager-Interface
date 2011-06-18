require 'rubygems'
require 'eventmachine'
require 'nexpose'

begin
  api = Nexpose::Connection.new 'localhost', 'v4test', 'buynexpose'
  api.login
  hosts = []
  host = {:host => 'localhost'}
  hosts <<  host
  api.site_device_scan_start 1, nil, hosts
end
