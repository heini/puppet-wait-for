Puppet::Type.type(:wait_for).provide(:wait_for) do
  desc "Waits for something to happen."

  def exit_code
    query = resource[:query]
    set_environment
    `#{query}`
    return $?
  end

  def exit_code=(expected_exit_code)
    fetch_parameters
    debug "Waiting until the exit code of #{@query} is #{expected_exit_code.to_s}"
    debug "Polling frequency #{@polling_frequency}, max retries #{@max_retries}"
    error_message = "wait_for timed out while waiting until the exit code of #{@query} became #{expected_exit_code}, after #{@max_retries} retries with polling frequency #{@polling_frequency}."
    query_and_wait(error_message) do |exit_code, output|
      if expected_exit_code == exit_code
        debug "Detected expected exit code."
        return expected_exit_code
      else
        debug "Exit code is #{exit_code} but we are waiting for #{expected_exit_code}."
      end
    end
  end

  def regex
    query = resource[:query]
    regex = resource[:regex]
    set_environment
    output = `#{query}`
    if output =~ /#{regex}/
      debug "Query output matched regex."
      return regex
    else
      return nil
    end
  end

  def regex=(regex)
    fetch_parameters
    debug "Waiting until the output of #{@query} matches #{regex.to_s}"
    debug "Polling frequency #{@polling_frequency}, max retries #{@max_retries}"
    error_message = "wait_for timed out while waiting until the output of #{@query} matched #{regex}, after #{@max_retries} retries with polling frequency #{@polling_frequency}."
    query_and_wait(error_message) do |exit_code, output|
      if output =~ /#{regex}/
        debug "Query output matched regex."
        return regex
      else
        debug "Query output #{output} did not match regex #{regex.to_s}."
      end
    end
  end

  def seconds
    seconds = resource[:seconds]
    debug "Waiting for #{seconds} seconds..."
    sleep(seconds)
    return seconds
  end

  private

  def fetch_parameters
    @query             = resource[:query]
    @polling_frequency = resource[:polling_frequency]
    @max_retries       = resource[:max_retries]
  end

  def set_environment
    environment = resource[:environment]
    environment.each do |item|
      (key, value) = item.split('=')
      debug "Setting environment variable #{key}."
      ENV[key] = value
    end
  end

  def query_and_wait(error_message)
    set_environment
    @max_retries.times do |i|
      debug "Retry #{i}"
      output    = `#{@query}`
      exit_code = $?
      debug "Exit code: #{exit_code.to_s}"
      debug "Output: #{output.to_s}"

      yield(exit_code, output)

      sleep @polling_frequency
    end

    fail error_message
  end
end
