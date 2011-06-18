require 'hirb'

#------------------------------------------------------------------------------------------------------
# A singleton scan listener class used to print scan status data
#------------------------------------------------------------------------------------------------------
class PrintScanListener

  private_class_method :new

  @@instance = nil

  def initialize
    @scan_table = []
  end

  def self.instance
    @@instance = new unless @@instance
    @@instance
  end

  #------------------------------------------------------------------------------------------------------
  # Implementation needed of all scan listeners. This listener just outputs scan data
  #
  # scan_info: Scan content: :scan_id, :status, :message
  # notifier: The onject that called this method
  #------------------------------------------------------------------------------------------------------
  def update scan_info, notifier
    table_changed = true
    object_in_table = false
    for i in 0..@scan_table.length-1
      scan_object = @scan_table[i]
      if scan_object[:scan_id] == scan_info[:scan_id]
        if  scan_object[:status].eql?scan_info[:status]
          # Nothing changed
          table_changed = false
        else
          @scan_table[i] = scan_info
          # table did change
        end
        object_in_table = true
        break
      end
    end

    if not object_in_table
      @scan_table << scan_info
    end

    if table_changed
      puts "\n"
      puts Hirb::Helpers::AutoTable.render @scan_table, :fields => [:scan_id, :status, :message], :description => false
    end

    status = scan_info[:status].chomp
    if 'finished'.eql? status  or 'stopped'.eql? status
      notifier.remove_scan_listener scan_info[:scan_id]
    end
  end

end