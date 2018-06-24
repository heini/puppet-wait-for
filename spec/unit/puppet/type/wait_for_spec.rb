require 'spec_helper'

describe Puppet::Type.type(:wait_for) do
  let(:wait_for) do
    Puppet::Type.type(:wait_for).new(:query => 'echo foo bar', :regex => 'foo')
  end

  test_data = {

    # Illustrating some consequences of acceptable input values due
    # to the type's data type coercion.
    #
    :exit_code   => [[42.5, 42], [[42], 42], [42, 42], ['42', 42]],
    :seconds     => [[42.5, 42], [[42], 42], [42, 42], ['42', 42]],
    :max_retries => [[42.5, 42], [42, 42], ['42', 42]],
    :polling_frequency => [[1.5, 1.5], [1, 1.0]],
    :regex             => [[/foo/, /foo/], ['foo', /foo/]],
  }

  test_data.each do |k,v|
    v.each do |val|
      i, o = val
      it "accepts #{k}=>#{i}" do
        wait_for[k] = i
        expect(wait_for[k]).to eq o
      end
    end
  end

  it 'does not raise error' do
    expect { wait_for }.not_to raise_error
  end

  bad_opts = [
    {:query  => 'echo foo bar', :regex  => 'foo', :exit_code => 42},
    {:query  => 'echo foo bar', :regex  => 'foo', :exit_code => 42, :seconds => 42},
    {:query  => 'echo foo bar', :regex  => 'foo', :seconds => 42},
    {:query  => 'echo foo bar', :exit_code => 42, :seconds => 42},
  ]

  bad_opts.each do |params|
    it "errors out with illegal opts #{params}" do
      expect { Puppet::Type.type(:wait_for).new(params) }.to raise_error(
        Puppet::Error, %r{Attributes regex, seconds and exit_code are mutually exclusive}
      )
    end
  end

  it 'errors out unless one of regex, seconds or exit_code is specified' do
    expect {
      Puppet::Type.type(:wait_for).new(
        :query  => 'echo foo bar',
      )
    }.to raise_error(
      Puppet::ResourceError, %r{Exactly one of regex, seconds or exit_code is required}
    )
  end

  it 'errors out if environment is not an array' do
    expect {
      Puppet::Type.type(:wait_for).new(
        :query  => 'echo foo bar',
        :environment => 'foo',
      )
    }.to raise_error(
      Puppet::ResourceError, %r{foo is not an array}
    )
  end

  it 'errors out if environment is not an array of strings like key=value' do
    expect {
      Puppet::Type.type(:wait_for).new(
        :query  => 'echo foo bar',
        :environment => ['foo'],
      )
    }.to raise_error(
      Puppet::ResourceError, %r{foo is not a key=value pair}
    )
  end

  defaults = {
    :polling_frequency => 0.5,
    :max_retries => 119,
    :environment => [],
  }

  defaults.each do |k,v|
    it "defaults #{k} => #{v}" do
      expect(wait_for[k]).to eq v
    end
  end
end
