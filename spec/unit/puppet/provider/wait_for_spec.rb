require 'spec_helper'

describe Puppet::Type.type(:wait_for).provider(:wait_for) do

  context '#run' do
    let(:resource) do
      Puppet::Type.type(:wait_for).new(
        :query => 'echo foo bar',
        :regex => 'baz',
      )
    end
    let(:provider) { resource.provider }

    it 'should run a command' do
      output = provider.run('echo foo bar')
      expect(output).to eq "foo bar\n"
    end
  end

  context '#seconds' do
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
end
