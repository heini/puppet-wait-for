# All of this code is based on the Exec builtin type.
#
# The code complexity in both Exec and in this derived Wait_for type
# comes from supporting the refreshonly concept, which does not fit
# Puppet's type/provider model. The hack in Exec and here is to not
# use the provider at all, and have the types themselves do most of
# the work.
#
# The Mixins module is used in the Wait_for type only to reuse the
# retrieve and sync methods. This is one point of departure from Exec.
# In Exec, retrieve and sync are defined only once on the :returns
# property. Here, they need to be defined on :exit_code, :query and
# :seconds.
#
module Mixins
  def self.included base
    base.send(:include, InstanceMethods)
  end

  module InstanceMethods

    # Defining a retrieve method stops Puppet looking for the
    # getter method in the provider.
    #
    def retrieve

      # Daniel Pittman's comment in the Exec source code:
      #
      # "We need to return :notrun to trigger evaluation; when that isn't
      # true, we *LIE* about what happened and return a "success" for the
      # value, which causes us to be treated as in_sync?, which means we
      # don't actually execute anything.  I think. --daniel 2011-03-10"
      #
      if @resource.check_all_attributes
        return :notrun
      else
        return self.should
      end
    end

    # Defining a sync stops Puppet looking for a setter method
    # in the provider. Basically, all the provider logic is implemented
    # here. Except the run method, although I think even that could
    # really be moved to here.
    #
    def sync
      if self.resource[:seconds]
        seconds = resource[:seconds]
        info "Waiting for #{seconds} seconds..."
        sleep seconds
        return seconds
      end

      tries = self.resource[:max_retries]
      polling_frequency = self.resource[:polling_frequency]

      status = false

      begin
        tries.times do |try|

          # Only add debug messages for tries > 1 to reduce log spam.
          debug("Wait_for try #{try+1}/#{tries}") if tries > 1

          # Handle command execution
          if self.resource[:query]
            @output = provider.run(self.resource[:query])

            if self.class == Puppet::Type::Wait_for::Exit_code
              status = self.should.include?(@output.exitstatus.to_i)
            elsif self.class == Puppet::Type::Wait_for::Regex
              status = @output =~ /#{self.should}/
            end
          elsif self.resource[:path]
            if self.class == Puppet::Type::Wait_for::State
              status = case self.should
                       when :absent
                         not File.exist?(self.resource[:path])
                       when :directory
                         File.directory?(self.resource[:path])
                       when :file
                         File.file?(self.resource[:path])
                       when :present
                         File.exist?(self.resource[:path])
                       end
            end
          end

          break if status

          if polling_frequency > 0 and tries > 1
            debug("Sleeping for #{polling_frequency} seconds between tries")
            sleep polling_frequency
          end
        end
      rescue Timeout::Error
        self.fail Puppet::Error, "Exceeded timeout", $!
      end

      unless status
        if self.class == Puppet::Type::Wait_for::Exit_code
          self.fail Puppet::Error, "Exit status #{@output.exitstatus.to_i} after max_retries"
        elsif self.class == Puppet::Type::Wait_for::Regex
          self.fail Puppet::Error, "Did not match regex after max_retries"
        elsif self.class == Puppet::Type::Wait_for::State
          case self.should
          when :absent
            self.fail Puppet::Error, "Filesystem element still present after max_retries"
          when :directory
            self.fail Puppet::Error, "Filesystem element isn't a directory or doesn't exist after max_retries"
          when :file
            self.fail Puppet::Error, "Filesystem element isn't a file or doesn't exist after max_retries"
          when :present
            self.fail Puppet::Error, "Filesystem element doesn't exist after max_retries"
          end
        end
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

    validate do |value|
      raise ArgumentError,
        "Regex must be of type String, got value of class #{value.class}" unless value.is_a?(String)
    end
  end

  newproperty(:state) do |property|
    include Mixins

    desc "If path is specified: Whether the filesystem element should be absent,
      present, a file or a directory.

      When present is specified, we only test for existence, regardles of type."

    newvalues(:absent, :directory, :file, :present)
  end

  newproperty(:seconds) do
    include Mixins
    desc "Just wait this number of seconds no matter what."

    munge do |value|
      value.to_f
    end
  end

  newparam(:title, :namevar => true) do
    desc "A short, unique description of what we're waiting for."

    validate do |value|
      raise ArgumentError,
        "Title must be of type String, got value of class #{value.class}" unless value.is_a?(String)
    end
  end

  newparam(:path) do
    desc "A path on the filesystem which should (dis-)appear."

    validate do |value|
      raise ArgumentError,
        "Path must be of type String, got value of class #{value.class}" unless value.is_a?(String)
    end
  end

  newparam(:query) do
    desc "The command to execute. The output of this command
      will be matched against the regex."

    validate do |command|
      raise ArgumentError,
        "Command must be of type String, got value of class #{command.class}" unless command.is_a?(String)
    end
  end

  newparam(:environment) do
    desc "An array of any additional environment variables you want to set for a
      command, such as `[ 'HOME=/root', 'MAIL=root@example.com']`.
      Multiple environment variables should be specified as an array."

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
          raise ArgumentError, "Max_retries must be an integer"
        end
        value = Integer(value)
      end
      raise ArgumentError, "Max_retries must be an integer >= 1" if value < 1
      value
    end

    defaultto 119
  end

  newparam(:polling_frequency) do
    desc "The time to sleep in seconds between 'tries'.

      This was copied from the Exec 'try_sleep' parameter."

    munge do |value|
      value = Float(value)
      raise ArgumentError, "Polling_frequency cannot be a negative number" if value < 0
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
      self.property(:seconds).sync   unless self.property(:seconds).nil?
      self.property(:state).sync   unless self.property(:state).nil?
      self.property(:type).sync   unless self.property(:type).nil?
    end
  end

  validate do
    # We either wait for some seconds, execute a command (query) or check a
    # path on the filesystem
    if ((self[:seconds] and not self[:path].nil?) or
        (self[:seconds] and not self[:query].nil?) or
        (not self[:query].nil? and not self[:path].nil?))
      fail "Attributes path, query and seconds are mutually exclusive."
    end

    # If a query command was provided, we either check for an exit code or a
    # regex, but not both
    if self[:query]
      unless ((self[:regex] and self[:exit_code].nil?) or
              (self[:exit_code] and self[:regex].nil?))
        fail "Exactly one of regex or exit_code is required."
      end
      # We also don't want the state of a filesystem element in this case
      if self[:state]
        fail "Attribute state is not allowed with query."
      end
    end

    # If a path was provided, we also expect a state...
    if self[:path]
      unless self[:state]
        fail "Attribute state is required together with path."
      end
      # ...but no regex or exit_code
      if self[:regex] or self[:exit_code]
        fail "Attributes regex and exit_code are not allowed with path."
      end
    end
  end
end
