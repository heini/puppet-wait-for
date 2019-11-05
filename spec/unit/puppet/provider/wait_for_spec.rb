require 'spec_helper'
require 'puppet/provider/wait_for/wait_for'

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
end
