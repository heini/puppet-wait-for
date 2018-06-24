require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec/mocks'

RSpec.configure do |c|
  c.formatter = :documentation
  c.tty       = true
  c.mock_with :rspec
end
