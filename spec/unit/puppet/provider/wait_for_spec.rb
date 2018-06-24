require 'spec_helper'

describe Puppet::Type.type(:wait_for).provider(:wait_for) do

  context 'query with regex that never matches' do
    let(:resource) do
      Puppet::Type.type(:wait_for).new(
        :query => 'echo foo bar',
        :regex => 'baz',
      )
    end
    let(:provider) { resource.provider }

    it 'should time out after 119 retries' do
      expect { provider.send(:regex) }.to_not raise_error
      expect_any_instance_of(Object).to receive(:sleep).with(0.5).exactly(119).times
      expect { provider.send('regex=', /baz/) }.to raise_error(
        Puppet::Error, %r{wait_for timed out})
    end
  end

  context 'query with regex that immediately matches' do
    let(:resource) do
      Puppet::Type.type(:wait_for).new(
        :query => 'echo foo bar',
        :regex => 'foo',
      )
    end
    let(:provider) { resource.provider }

    it 'should immediately succeed if regex matches' do
      expect(provider.send(:regex)).to be_truthy
    end
  end

  context 'query with regex with custom polling_interval and max_retries' do
    let(:resource) do
      Puppet::Type.type(:wait_for).new(
        :query             => 'echo foo bar',
        :regex             => 'baz',
        :polling_frequency => 1,
        :max_retries       => 10,
      )
    end
    let(:provider) { resource.provider }

    it 'should time out after 10 retries' do
      expect { provider.send(:regex) }.to_not raise_error
      expect_any_instance_of(Object).to receive(:sleep).with(1).exactly(10).times
      expect { provider.send('regex=', /baz/) }.to raise_error(
        Puppet::Error, %r{wait_for timed out})
    end
  end

  context 'sleep for a number of seconds' do
    let(:resource) do
      Puppet::Type.type(:wait_for).new(
        :name    => 'a_minute',
        :seconds => 60,
      )
    end
    let(:provider) { resource.provider }

    it 'should sleep for 60 seconds' do
      expect_any_instance_of(Object).to receive(:sleep).with(60).once
      provider.send(:seconds)
    end
  end

  context 'wait for an exit code' do
    # TODO. Not easy to test due to use of $? which, as far as I can tell, cannot be stubbed,
    # e.g. https://stackoverflow.com/questions/4589460/is-there-a-way-to-set-the-value-of-in-a-mock-in-ruby
  end
end
