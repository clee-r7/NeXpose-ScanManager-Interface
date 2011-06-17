require 'rubygems'
require 'rake'

Gem::Specification.new do |spec|
	spec.name = 'nexpose_scan_manager'
	spec.version = '0.0.3'
	spec.platform=Gem::Platform::RUBY
  spec.description=
<<Description
	NeXpose Scan Manager is used for launching and asynchronous polling and processing of NeXpose scans
  via the NeXpose API.  It can also handle load-aware batched & queued scanning
Description
	spec.summary=
<<Summary
	NeXpose Scan Manager is used for launching and asynchronous polling and processing of NeXpose scans
  via the NeXpose API.  It can also handle load-aware batched & queued scanning.
Summary
	spec.add_dependency 'nexpose', '>= 0.0.3'
	spec.add_dependency 'eventmachine-eventmachine', '>= 0.12.9'
	spec.author = 'Christopher Lee'
	spec.email = 'christopher_lee@rapid7.com'
	spec.files = FileList['lib/*'].to_a
  spec.extra_rdoc_files = ['README']
end