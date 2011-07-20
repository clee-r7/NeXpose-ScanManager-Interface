class Util

  #------------------------------------------------------------------------------------------------------
  # Checks if the input is a number
  #
  # input: The object that will be tested
  #------------------------------------------------------------------------------------------------------
  def self.is_number? input
    true if Float input rescue false
  end

  #------------------------------------------------------------------------------------------------------
  # Retrieves numeric input only from the command line
  #
  # mssg: The message to display that requests the input
  #------------------------------------------------------------------------------------------------------
  def self.get_numeric_input mssg
      begin
        while true
          print mssg
          input = gets().chomp()
          if Util.is_number? input
            return input.to_i
          else
            puts "Input is not a number"
          end
        end
        rescue Exception => e
            puts e.message
      end
    end

end