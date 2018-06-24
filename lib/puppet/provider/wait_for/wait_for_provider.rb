Puppet::Type.type(:wait_for).provide(:wait_for) do
  desc "Waits for something to happen."

  def exit_code
    fetch_parameters
    set_environment
    `#{@query}`
    return $?
  end

  def exit_code=(expected)
    info "waiting until the exit code of #{@query} is #{expected}"
    info "polling frequency #{@polling_frequency}, max retries #{@max_retries}"

    message = set_message("the exit code of #{@query} became #{expected}")

    query_and_wait(message) do |exit_code, output|
      if expected == exit_code
        info "Detected expected exit code."
        return expected
      else
        debug "Exit code is #{exit_code} but we are waiting for #{expected}."
      end
    end
  end

  def regex
    fetch_parameters
    set_environment
    output = `#{@query}`
    if output =~ @regex
      info "Query output matched regex."
      return @regex
    else
      return nil
    end
  end

  def regex=(regex)
    fetch_parameters

    info "waiting until the output of #{@query} matches #{regex}"
    info "polling frequency #{@polling_frequency}, max retries #{@max_retries}"

    message = set_message("the output of #{@query} matched #{regex}")

    query_and_wait(message) do |exit_code, output|
      if output =~ regex
        info "Query output matched regex."
        return regex
      else
        debug "Query output #{output} did not match regex #{regex}."
      end
    end
  end

  def seconds
    fetch_parameters
    info "Waiting for #{@seconds} seconds..."
    sleep(@seconds)
    return @seconds
  end

 private

  def fetch_parameters
    @query    = resource[:query]
    @regex    = resource[:regex]
    @seconds  = resource[:seconds]
    @environment = resource[:environment]
    @max_retries = resource[:max_retries]
    @polling_frequency = resource[:polling_frequency]
  end

  def set_environment
    @environment.each do |item|
      key, value = item.split('=')
      debug "Setting environment variable #{key}."
      ENV[key] = value
    end
  end

  def set_message(reason)
    return "wait_for timed out while waiting until #{reason}, " \
      "after #{@max_retries} retries " \
      "with polling frequency #{@polling_frequency}."
  end

  def query_and_wait(message)
    1.upto(@max_retries) do |i|

      output    = `#{@query}`
      exit_code = $?

      debug "Retry #{i}"
      debug "exit code: #{exit_code}"
      debug "output: #{output}"

      yield(exit_code, output)

      sleep @polling_frequency
    end

    fail message
  end
end
