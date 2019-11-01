require 'puppet/util/execution'

# Most of this code is copied from the Exec provider.
#
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
        output = Puppet::Util::Execution.execute(
          command,
          :failonfail => false,
          :combine => true,
          :override_locale => true,
          :custom_environment => environment)
      end
      # The shell returns 127 if the command is missing.
      if output.exitstatus == 127
        raise ArgumentError, output
      end

    rescue Errno::ENOENT => detail
      self.fail Puppet::Error, detail.to_s, detail
    end

    return output
  end

  def seconds
    seconds = resource[:seconds]
    info "Waiting for #{seconds} seconds..."
    sleep seconds
    return seconds
  end
end
