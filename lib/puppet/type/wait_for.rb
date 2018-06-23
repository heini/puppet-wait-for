# These methods in the Mixins module get "mixed in" to the
# Exit_code and Regex methods (i.e. properties) below.
#
module Mixins
  def self.included base
    base.send(:include, InstanceMethods)
  end

  module InstanceMethods

    # Defining a retrieve method seems to stop Puppet looking for an
    # getter method in the provider.
    #
    # The idea is copied from the Exec type.
    #
    def retrieve

      # See comments about how this works by Daniel Pittman in the Exec
      # Puppet source code.
      #
      if @resource.check_all_attributes
        return :notrun
      else
        return self.should
      end
    end

    # Defining a sync method seems to stop Puppet looking for an
    # setter method in the provider.
    #
    def sync
      tries = self.resource[:max_retries]
      polling_frequency = self.resource[:polling_frequency]

      begin
        tries.times do |try|

          # Only add debug messages for tries > 1 to reduce log spam.
          #
          debug("Wait_for try #{try+1}/#{tries}") if tries > 1
          @output = provider.run(self.resource[:query])

          if self.class == Puppet::Type::Wait_for::Exit_code
            break if self.should.include?(@output.exitstatus.to_i)
          elsif self.class == Puppet::Type::Wait_for::Regex
            break if @output =~ self.should
          end

          if polling_frequency > 0 and tries > 1
            debug("Sleeping for #{polling_frequency} seconds between tries")
            sleep polling_frequency
          end
        end
      rescue Timeout::Error
        self.fail Puppet::Error, "Query exceeded timeout", $!
      end
    end
  end
end

Puppet::Type.newtype(:wait_for) do
  @doc = "Wait for something to happen.

    This was based on an original idea by Bastian Krol and then later
    rewritten, using the built-in Exec type as a starting point, in
    order to implement Exec's refreshonly functionality.

    A lot of this code is copy/pasted from Exec."

  # Create a new check mechanism.  It's basically just a parameter that
  # provides one extra 'check' method.
  #
  # This is copied from the Exec type, in support of the :refreshonly
  # feature.
  #
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
  # within refresh.
  #
  # Copied from Exec, in support of the :refreshonly feature.
  #
  def check_all_attributes(refreshing = false)
    self.class.checks.each { |check|
      next if refreshing and check == :refreshonly
      if @parameters.include?(check)
        val = @parameters[check].value
        val = [val] unless val.is_a?(Array)
        val.each do |value|
          return false unless @parameters[check].check(value)
        end
      end
    }
    true
  end

  newproperty(:exit_code, :array_matching => :all) do |property|
    include Mixins

    desc "The expected exit code(s). An error will be returned if the
      executed command has some other exit code. Defaults to 0. Can be
      specified as an array of acceptable exit codes or a single value.

      This property is based on the Exec returns property."

    munge do |value|
      value.to_i
    end
  end

  newproperty(:regex) do |property|
    include Mixins

    desc "A regex pattern that is used in conjunction with the
      query parameter. The query is executed, and wait_for waits
      for that pattern to be seen, timing out after :max_retries
      retries."

    munge do |value|
      Regexp.new(value)
    end
  end

  newproperty(:seconds) do
    desc "Just wait this number of seconds no matter what."
    munge do |value|
      value.to_i
    end
  end

  newparam(:query) do
    desc "The command to execute. The output of this command
      will be matched against the regex."

    isnamevar

    validate do |command|
      raise ArgumentError,
        "Command must be a String, got value of class #{command.class}" unless command.is_a?(String)
    end
  end

  newparam(:environment) do
    desc "An array of any additional environment variables you want to set for a
      command, such as `[ 'HOME=/root', 'MAIL=root@example.com']`.
      Note that if you use this to set PATH, it will override the `path`
      attribute. Multiple environment variables should be specified as an
      array.

      This was copied from the Exec type."

    validate do |values|
      values = [values] unless values.is_a?(Array)
      values.each do |value|
        unless value =~ /\w+=/
          raise ArgumentError, "Invalid environment setting '#{value}'"
        end
      end
    end
  end

  newparam(:timeout) do
    desc "The maximum time the command (query) should take.  If the command
      takes longer than the timeout, the command is considered to have failed
      and will be stopped. The timeout is specified in seconds. The default
      timeout is 300 seconds and you can set it to 0 to disable the timeout.

      This was copied from the Exec type."

    munge do |value|
      value = value.shift if value.is_a?(Array)
      begin
        value = value.to_f
      rescue ArgumentError
        raise ArgumentError, "The timeout must be a number.", $!.backtrace
      end
      raise ArgumentError, "The timeout cannot be a negative number" if value < 0
    end

    defaultto 300
  end

  newparam(:max_retries) do
    desc "The number of times execution of the command should be retried.
      This many attempts will be made to execute the command until either an
      acceptable return code is returned or the regex is matched.
      Note that the timeout parameter applies to each try rather than
      to the complete set of tries.

      This was copied from the Exec 'tries' parameter."

    munge do |value|
      if value.is_a?(String)
        unless value =~ /^[\d]+$/
          raise ArgumentError, "Tries must be an integer"
        end
        value = Integer(value)
      end
      raise ArgumentError, "Tries must be an integer >= 1" if value < 1
      value
    end

    defaultto 119
  end

  newparam(:polling_frequency) do
    desc "The time to sleep in seconds between 'tries'.

      This was copied from the Exec 'try_sleep' parameter."

    munge do |value|
      value = Float(value)
      raise ArgumentError, "polling_frequency cannot be a negative number" if value < 0
      value
    end

    defaultto 0.5
  end

  newcheck(:refreshonly) do
    desc "Based on the Exec refreshonly parameter.

      The command should only be run as a
      refresh mechanism for when a dependent object is changed.  It only
      makes sense to use this option when this command depends on some
      other object; it is useful for triggering an action:

          service { 'logstash':
            ensure => running,
            enable => true,
          }

          # Wait for the service to really start.
          wait_for { 'logstash':
            query             => 'cat /var/log/logstash/logstash-plain.log 2> /dev/null',
            regex             => 'Successfully started Logstash API endpoint',
            polling_frequency => 5,  # Wait up to 2 minutes.
            max_retries       => 24,
            refreshonly       => true,
          }

      Note that only `subscribe` and `notify` can trigger actions, not `require`,
      so it only makes sense to use `refreshonly` with `subscribe` or `notify`."

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

  def refresh
    if self.check_all_attributes(true)
      self.property(:exit_code).sync unless self.property(:exit_code).nil?
      self.property(:regex).sync     unless self.property(:regex).nil?
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
