require 'rubygems'
require 'eventmachine'
require 'thread'
require 'observer'
require 'nexpose'

=begin rdoc
 Used to start site device scans where a user is able to specify the maximum amount of scans that
 should be running at a time.  This class does not guarantee that there will be no more than the
 maximum amount of scans specified will be running BUT scans will not be started from this class
 until the current amount of scans running is less than or equal to the maximum.

 This class can also be used to monitor the state of a running scan.
=end

class ScanManager
  include Observable

  # Used to determine if the poller thread is running
  attr_accessor :is_poller_thread_running

  # Determines how often the poller thread is executed
  attr_reader :period

  # Synchronize calls that modify open data structs
  @semaphore = nil

  # The NeXpose API object.
  @nexpose_conn = nil

  # A Hash of scan-ids to an array of operations for that scan
  # All tasks associated with a scan id must implement #scan_update
  @conditional_device_scans = nil
  @excution_cycle_started = nil
  @poler_exit_on_completion = nil

  private
    def start_poller
      @is_poller_thread_running = true
      operation = proc {
        puts "Scan Manager poller thread executing ..."
        while true do
          sleep @period.to_i
          check_and_execute_op
          if @execution_cycle_started and @conditional_device_scans.empty? and @scan_listeners.empty? and @poler_exit_on_completion
            break
          end
        end

        @is_poller_thread_running = false
        puts "Poller exiting ..."
      }

      EM.defer operation
    end

    def check_and_execute_op
      @semaphore.synchronize do

        @scans_observed.each do |scan_id|
          status = @nexpose_conn.scan_status scan_id
          scan_stats = @nexpose_conn.scan_statistics scan_id
          message = scan_stats[:message]


          content = {
            :scan_id => scan_id,
            :status  => status,
            :message => message
          }

          changed
          notify_observers content, self
        end

        # We start scans one per thread execution loop.
        # Then we start the scan if conditions are met.
        # NOTE: the only condition implemented here is the maximum amount of scans.
        if @conditional_device_scans.length > 0
          scan_count = 0
          stats = @nexpose_conn.scan_activity

          # Get a count of all the running scans
          stats.each do |stat|
            if (stat[:status].eql?('running') or stat[:status].eql?('dispatched'))
              scan_count = scan_count + 1
            end
          end

          for i in 0..(@conditional_device_scans.length-1)
              scan_condition = @conditional_device_scans[i]
              if scan_condition[:max_scans] > scan_count
                res = @nexpose_conn.site_device_scan_start scan_condition[:site_id], scan_condition[:devices], scan_condition[:hosts]
                if res
                  puts "Scan started scan ID: #{res[:scan_id]}, on engine ID: #{res[:engine_id]}"
                  @conditional_device_scans.delete_at i
                  @scans_observed << res[:scan_id]
                else
                  put "Scan start failed for site #{site}"
                end

                break # Only one scan per loop can be started
              end
          end
        end
      end # End of synchronize block
    end

  public

    #
    # The poller thread used within this class is initialized here.
    #
    # nexpose_conn: The NeXpose API object
    # poler_exit_on_completion: 'true', if the poller thread should exit when
    # when there is nothing left to process.
    # period: The frequency at which the poller thread executes
    #
    def initialize nexpose_conn, poler_exit_on_completion, period
      @nexpose_conn = nexpose_conn
      @period = period
      @poler_exit_on_completion = poler_exit_on_completion
      @semaphore = Mutex.new
      @conditional_device_scans = []
      @scans_observed = []
      @execution_cycle_started = false

      start_poller
    end

    #
    # Adds a scan to be observed
    # scan_id: The ID of the scan to be observed.
    #
    def add_scan_observed scan_id
      puts "Obeserving scan #{scan_id}"
      @scans_observed << scan_id
    end

    #
    # Removes a currently observed scan
    # scan_id: The ID of the scan to be removed.
    #
    def remover_scan_observed scan_id
      @scans_observed.delete scan_id 
    end

    #
    # Starts device site scans based on a particular condition, for now this is if the max amount of scans
    # specified is greater than the amount of currently running scans.
    #
    # conditional_scan: A hash of informations used to start scanning
    # ie : @[0] -> :site_id => 1 :devices => [192.168.1.1] :max_scans => 5 :listeners => [listerner_objects]
  def add_cond_scan conditional_scan
    if conditional_scan.nil?
      raise ArgumentError 'Condtional scan arguement is null'
    end

    @semaphore.synchronize do
      @conditional_device_scans << conditional_scan
      if not @execution_cycle_started
        @execution_cycle_started = true
      end
    end
  end
end