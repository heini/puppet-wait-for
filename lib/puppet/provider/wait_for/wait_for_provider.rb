Puppet::Type.type(:wait_for).provide(:wait_for) do
    desc "Waits for something to happen."

    def exit_code
        expected_exit_code = resource[:exit_code]
        fetch_parameters
        info "waiting until the exit code of #{@query} is #{expected_exit_code.to_s}"
        info "polling frequency #{@polling_frequency}, max retries #{@max_retries}"
        query_and_wait do |exit_code, output|
            if expected_exit_code == exit_code
                info "Detected expected exit code."
                return expected_exit_code
            else
                debug "Exit code is #{exit_code} but we are waiting for #{expected_exit_code}."
            end
        end
        return nil
    end
 
    def regex
        regex = resource[:regex]
        fetch_parameters
        info "waiting until the output of #{@query} matches #{regex.to_s}"
        info "polling frequency #{@polling_frequency}, max retries #{@max_retries}"
        query_and_wait do |exit_code, output|
            if output =~ regex
                info "Query output matched regex."
                return regex
            else
                debug "Query output #{output} did not match regex #{regex.to_s}."
            end
        end
        return nil
    end


    private

    def fetch_parameters
        @query = resource[:query]
        @polling_frequency = resource[:polling_frequency]
        @max_retries = resource[:max_retries]
    end

    def query_and_wait
        for i in 1..@max_retries
            debug "Retry #{i}"
            output = `#{@query}`
            debug "exit code: #{$?.to_s}"
            debug "output: #{output.to_s}"
            
            yield($?, output)

            sleep @polling_frequency
        end

        # TODO Is this the correct way to signal that we failed to
        # "synchronize the resource"? (Okay, we're not actually synchronizing
        # any resource, so what.)
        fail "wait_for timed out after #{@max_retries} retries (polling frequency: #{@polling_frequency})."
    end
end
