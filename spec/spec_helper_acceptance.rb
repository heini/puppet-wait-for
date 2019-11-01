require 'beaker-pe'
require 'beaker-puppet'
require 'beaker-rspec'
require 'beaker/puppet_install_helper'
require 'puppet'

run_puppet_install_helper

UNSUPPORTED_PLATFORMS = ['Solaris','Darwin']

RSpec.configure do |c|
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  c.formatter = :documentation

  c.before :suite do
    hosts.each do |host|
      copy_module_to(
        host,
        :target_module_path => '/etc/puppetlabs/code/modules',
        :source => proj_root,
        :module_name => 'wait_for')
    end
  end
end
