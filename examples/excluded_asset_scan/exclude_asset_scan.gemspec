require 'rubygems'
require 'rake'

Gem::Specification.new do |spec|
	spec.name = 'excl_site_asset_scan'
	spec.version = '0.0.1'
	spec.platform=Gem::Platform::RUBY
	spec.homepage='https://github.com/chrlee/NeXpose-ScanManager-Interface/tree/master/examples/excluded_asset_scan'
	spec.description=
<<Description
  	List asset groups, list information about certain asset groups, start a site scan with certain asset groups excluded.
Description
	spec.summary=
<<Summary
	List asset groups, list information about certain asset groups, start a site scan with certain asset groups excluded.
Summary
	spec.add_dependency 'nexpose', '>= 0.0.3'
	spec.add_dependency 'hirb', '>= 0.4.5'
	spec.author = 'Christopher Lee'
	spec.email = 'christopher_lee@rapid7.com'
	spec.executables = ['nexpose_api_util']
	spec.files = FileList['lib/*'].to_a
end
