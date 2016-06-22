# A type to wait for a command to return an expected output
Puppet::Type.newtype(:wait_for) do
    @doc = "Waits for something to happen."

    newparam(:query, :namevar => true) do
        desc "The command to execute, the output of this command will be matched against regex."
    end

    newproperty(:exit_code) do
        desc "The exit code to expect."
        munge do |value|
          Integer(value)
        end
    end

    newproperty(:regex) do
        desc "The regex to match the commmand's output against."
        munge do |value|
          Regexp.new(value)
        end
    end

    newproperty(:seconds) do
        desc "How long to just wait."
        munge do |value|
          Integer(value)
        end
    end

    newparam(:polling_frequency) do
        desc "How long to sleep in between retries."
        defaultto 0.5
        munge do |value|
          Float(value)
        end
    end

    newparam(:max_retries) do
        desc "How often to retry the query before timing out."
        defaultto 119 
        munge do |value|
          Integer(value)
        end
    end
  
    newparam(:environment, :array_matching => :all) do
        desc "An array of strings of the form 'key=value', which will be injected into the environment of the query command."
        defaultto []
        munge do |value|
          Array(value)
        end
        validate do |value|
            value.each do |item|
                unless item =~ /^\w+=.*/
                    raise ArgumentError, "%s is not a key=value pair" % item
                end
            end
        end
    end

    validate do
        unless self[:regex] or self[:exit_code] or self[:seconds]
            fail "Exactly one of regex, seconds or exit_code is required."
        end
        if self[:regex] and self[:exit_code] or self[:regex] and self[:seconds] or self[:exit_code] and self[:seconds]
            fail "Attributes regex, seconds and exit_code are mutually exclusive."
        end
    end
end
