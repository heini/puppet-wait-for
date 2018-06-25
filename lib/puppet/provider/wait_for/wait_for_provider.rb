require 'puppet/util/execution'

Puppet::Type.type(:wait_for).provide(:wait_for) do
  include Puppet::Util::Execution

  def run(command)
    output = nil

    begin
      environment = {}
      if envlist = resource[:environment]
        envlist = [envlist] unless envlist.is_a? Array
        envlist.each do |setting|
          if setting =~ /^(\w+)=((.|\n)+)$/
            env_name = $1
            value = $2
            if environment.include?(env_name) || environment.include?(env_name.to_sym)
              warning _("Overriding environment setting '%{env_name}' with '%{value}'") % { env_name: env_name, value: value }
            end
            environment[env_name] = value
          else
            warning _("Cannot understand environment setting %{setting}") % { setting: setting.inspect }
          end
        end
      end

      # Ruby 2.1 and later interrupt execution in a way that bypasses error
      # handling by default. Passing Timeout::Error causes an exception to be
      # raised that can be rescued inside of the block by cleanup routines.
      #
      # This is backwards compatible all the way to Ruby 1.8.7.
      Timeout::timeout(resource[:timeout], Timeout::Error) do
        # note that we are passing "false" for the "override_locale" parameter, which ensures that the user's
        # default/system locale will be respected.  Callers may override this behavior by setting locale-related
        # environment variables (LANG, LC_ALL, etc.) in their 'environment' configuration.
        output = Puppet::Util::Execution.execute(['/bin/sh', '-c', command],
                                :failonfail => false,
                                :combine => true,
                                :override_locale => false,
                                :custom_environment => environment)
      end
      # The shell returns 127 if the command is missing.
      if output.exitstatus == 127
        raise ArgumentError, output
      end

    rescue Errno::ENOENT => detail
      self.fail Puppet::Error, detail.to_s, detail
    end

    # Return output twice as processstatus was returned before, but only exitstatus was ever called.
    # Output has the exitstatus on it so it is returned instead. This is here twice as changing this
    #  would result in a change to the underlying API.
    return output, output
  end
end
