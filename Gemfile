source 'https://rubygems.org'

group :development do
  gem 'pdk'
  gem 'pry'
  gem 'pry-rescue'
  gem 'pry-stack_explorer'
end

group :tests do
  gem 'rspec-mocks'
  gem 'puppetlabs_spec_helper'
  gem 'puppet-blacksmith'
end

group :system_tests do
  gem 'beaker'
  gem 'beaker-rspec'
  gem 'beaker-puppet_install_helper'
  gem 'beaker-vagrant'
  gem 'beaker-pe'
end

gem 'facter'

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion
else
  gem 'puppet'
end
