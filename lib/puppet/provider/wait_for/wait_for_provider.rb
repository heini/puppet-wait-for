Puppet::Type.type(:wait_for).provide(:wait_for) do
    desc "Waits for something to happen."

    def waitfor
        @polling_frequency = resource[:polling_frequency]
        @max_retries = resource[:max_retries]
        @query = resource[:query]

        regex = resource[:regex]
        expected_exit_code = resource[:exit_code]

        if regex != nil then
          
            info "waiting until the output of #{@query} matches #{regex.to_s}"
            info "polling frequency #{@polling_frequency}, max retries #{@max_retries}"
            query_and_wait do |exit_code, output|
                if output =~ regex
                    info "Query output matched regex."
                    return true
                else
                    debug "Query output did not match regex."
                end
            end

        elsif expected_exit_code != nil then

            info "waiting until the exit code of #{@query} is #{expected_exit_code.to_s}"
            info "polling frequency #{@polling_frequency}, max retries #{@max_retries}"
            query_and_wait do |exit_code, output|
                if expected_exit_code == exit_code
                    info "Detected expected exit code."
                    return true
                else
                    debug "Exit code is #{exit_code} but we are waiting for #{expected_exit_code}."
                end
            end

       else
            fail "This should not have happened - neither regex nor exit_code are defined. The validation in the wait_for type should have detected that."
        end

    end

    private

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
