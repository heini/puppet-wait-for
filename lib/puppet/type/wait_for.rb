# A type to wait for a command to return an expected output
Puppet::Type.newtype(:wait_for) do
  @doc = "Waits for something to happen."

  ## Begin copy/paste from exec.

  # Create a new check mechanism.  It's basically just a parameter that
  # provides one extra 'check' method.
  def self.newcheck(name, options = {}, &block)
    @checks ||= {}

    check = newparam(name, options, &block)
    @checks[name] = check
  end

  def self.checks
    @checks.keys
  end

  # Verify that we pass all of the checks.  The argument determines whether
  # we skip the :refreshonly check, which is necessary because we now check
  # within refresh
  def check_all_attributes(refreshing=false)
    self.class.checks.each { |check|  # I think "checks" are newchecks, here only one.
      next if refreshing and check == :refreshonly

      if @parameters.include?(check) # @parameters comes from Puppet::Type
        val = @parameters[check].value
        val = [val] unless val.is_a? Array
        val.each do |value|
          return false unless @parameters[check].check(value)
        end
      end
    }

    true
  end

  # Run the command, or optionally run a separately-specified command.
  def refresh
    self.check_all_attributes(true)

      # FIXME. Delete. Copied from Exec. Not needed here.
      #
      # if cmd = self[:refresh]
      #   provider.run(cmd)
      # else
      #   self.property(:returns).sync
      # end
    end
  end

  newcheck(:refreshonly) do
    newvalues(:true, :false)

    # We always fail this test, because we're only supposed to run
    # on refresh.
    def check(value)
      # We have to invert the values.
      if value == :true
        false
      else
        true
      end
    end
  end

  ## End copy/paste from exec.

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
    validate do |value|
      unless value.is_a?(Array)
        raise ArgumentError, "#{value} is not an array"
      end
      value.each do |item|
        unless item =~ /^\w+=.*/
          raise ArgumentError, "#{item} is not a key=value pair"
        end
      end
    end
  end

  validate do
    unless self[:regex] or self[:exit_code] or self[:seconds]
      fail "Exactly one of regex, seconds or exit_code is required."
    end
    if (self[:regex] and not self[:exit_code].nil?) or
       (self[:regex] and not self[:seconds].nil?) or
       (not self[:exit_code].nil? and not self[:seconds].nil?)
      fail "Attributes regex, seconds and exit_code are mutually exclusive."
    end
  end
end
