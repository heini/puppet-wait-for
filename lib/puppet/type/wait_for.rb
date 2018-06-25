module Puppet
  Type.newtype(:wait_for) do
    include Puppet::Util::Execution
    require 'timeout'

    @doc = "TODO"

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

    newproperty(:exit_code, :array_matching => :all) do |property|
      desc "TODO"

      include Puppet::Util::Execution

      attr_reader :output

      munge do |value|
        value.to_s
      end

      defaultto 0

      # First verify that all of our checks pass.
      def retrieve
        # We need to return :notrun to trigger evaluation; when that isn't
        # true, we *LIE* about what happened and return a "success" for the
        # value, which causes us to be treated as in_sync?, which means we
        # don't actually execute anything.  I think. --daniel 2011-03-10
        if @resource.check_all_attributes
          return :notrun
        else
          return self.should
        end
      end

      # Actually wait for the exit code.
      def sync
        tries = self.resource[:max_retries]
        try_sleep = self.resource[:polling_frequency]

        begin
          tries.times do |try|
            # Only add debug messages for tries > 1 to reduce log spam.
            debug("Exec try #{try+1}/#{tries}") if tries > 1
            @output, @status = provider.run(self.resource[:query])
            break if self.should.include?(@status.exitstatus.to_s)
            if try_sleep > 0 and tries > 1
              debug("Sleeping for #{try_sleep} seconds between tries")
              sleep try_sleep
            end
          end
        rescue Timeout::Error
          self.fail Puppet::Error, _("Query exceeded timeout"), $!
        end
      end
    end

    newparam(:query) do
      isnamevar
      desc ""

      validate do |command|
        raise ArgumentError, _("Command must be a String, got value of class %{klass}") % { klass: command.class } unless command.is_a? String
      end
    end

    newparam(:environment) do
      desc ""

      validate do |values|
        values = [values] unless values.is_a? Array
        values.each do |value|
          unless value =~ /\w+=/
            raise ArgumentError, _("Invalid environment setting '%{value}'") % { value: value }
          end
        end
      end
    end

    newparam(:timeout) do
      desc ""

      munge do |value|
        value = value.shift if value.is_a?(Array)
        begin
          value = Float(value)
        rescue ArgumentError
          raise ArgumentError, _("The timeout must be a number."), $!.backtrace
        end
        [value, 0.0].max
      end

      defaultto 300
    end

    newparam(:max_retries) do
      desc "The number of times execution of the command should be tried.
        Defaults to '1'. This many attempts will be made to execute
        the command until an acceptable return code is returned.
        Note that the timeout parameter applies to each try rather than
        to the complete set of tries."

      munge do |value|
        if value.is_a?(String)
          unless value =~ /^[\d]+$/
            raise ArgumentError, _("Tries must be an integer")
          end
          value = Integer(value)
        end
        raise ArgumentError, _("Tries must be an integer >= 1") if value < 1
        value
      end

      defaultto 1
    end

    newparam(:polling_frequency) do
      desc "The time to sleep in seconds between 'tries'."

      munge do |value|
        value = Integer(value)
        raise ArgumentError, _("polling_frequency cannot be a negative number") if value < 0
        value
      end

      defaultto 0
    end

    newcheck(:refreshonly) do
      desc <<-'EOT'
      EOT

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

    # Verify that we pass all of the checks.  The argument determines whether
    # we skip the :refreshonly check, which is necessary because we now check
    # within refresh
    def check_all_attributes(refreshing = false)
      self.class.checks.each { |check|
        next if refreshing and check == :refreshonly
        if @parameters.include?(check)
          val = @parameters[check].value
          val = [val] unless val.is_a? Array
          val.each do |value|
            return false unless @parameters[check].check(value)
          end
        end
      }

      true
    end

    def output
      if self.property(:exit_code).nil?
        return nil
      else
        return self.property(:exit_code).output
      end
    end

    def refresh
      if self.check_all_attributes(true)
        self.property(:exit_code).sync
      end
    end
  end
end
