source 'https://rubygems.org'

group :development do
  gem 'pry'
  gem 'pry-rescue'
  gem 'pry-stack_explorer'
end

group :tests do
  gem 'rspec-mocks'
  gem 'puppetlabs_spec_helper'
end

gem 'facter'

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion
else
  gem 'puppet'
end
