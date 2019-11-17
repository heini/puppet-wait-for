require 'spec_helper'

describe Puppet::Type.type(:wait_for) do
  let(:wait_for) do
    Puppet::Type.type(:wait_for).new(:title => 'Testing with regex', :query => 'echo foo bar', :regex => 'foo')
  end

  let(:wait_for_seconds) do
    Puppet::Type.type(:wait_for).new(:title => 'Wait for some seconds')
  end

  test_data = {

    # Illustrating some consequences of acceptable input values due
    # to the type's data type coercion.
    #
    :exit_code   => [[42.5, [42]], [[42], [42]], [42, [42]], ['42', [42]], [[1,'2','42'], [1,2,42]]],
    :max_retries => [[42.5, 42.5], [42, 42], ['42', 42]],
    :polling_frequency => [[1.5, 1.5], [1, 1.0]],
    :regex             => [['foo', 'foo']],
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

  test_data_seconds = {
    :seconds => [[42.5, 42.5], [[42], 42], [42, 42], ['42', 42]],
  }

  test_data_seconds.each do |k,v|
    v.each do |val|
      i, o = val
      it "accepts #{k}=>#{i}" do
        wait_for_seconds[k] = i
        expect(wait_for_seconds[k]).to eq o
      end
    end
  end

  bad_opts = [
    {:title => 'Error case 1', :query => 'echo foo bar', :path => '/tmp/foo'},
    {:title => 'Error case 2', :query => 'echo foo bar', :path => '/tmp/foo', :seconds => 42},
    {:title => 'Error case 3', :path => '/tmp/foo', :seconds => 42},
    {:title => 'Error case 4', :query => 'echo foo bar', :seconds => 42},
  ]

  bad_opts.each do |params|
    it "errors out with illegal opts #{params}" do
      expect { Puppet::Type.type(:wait_for).new(params) }.to raise_error(
        Puppet::Error, %r{Attributes path, query and seconds are mutually exclusive.}
      )
    end
  end

  it 'errors out unless one of regex or exit_code is specified' do
    expect {
      Puppet::Type.type(:wait_for).new(
        :title => 'Error case 5',
        :query  => 'echo foo bar',
      )
    }.to raise_error(
      Puppet::ResourceError, %r{Exactly one of regex or exit_code is required.}
    )
  end

  it 'errors out if environment is not an array' do
    expect {
      Puppet::Type.type(:wait_for).new(
        :title => 'Error case 6',
        :query  => 'echo foo bar',
        :environment => 'foo',
      )
    }.to raise_error(
      Puppet::ResourceError, %r{Invalid environment setting 'foo'}
    )
  end

  it 'errors out if environment is not an array of strings like key=value' do
    expect {
      Puppet::Type.type(:wait_for).new(
        :title => 'Error case 7',
        :query  => 'echo foo bar',
        :environment => ['foo'],
      )
    }.to raise_error(
      Puppet::ResourceError, %r{Invalid environment setting 'foo'}
    )
  end

  it 'errors out if regex is not a string' do
    expect {
      Puppet::Type.type(:wait_for).new(
        :title => 'Error case 8',
        :query  => 'echo foo bar',
        :regex => /foo/,
      )
    }.to raise_error(
      Puppet::ResourceError, %r{Regex must be of type String}
    )
  end

  defaults = {
    :polling_frequency => 0.5,
    :max_retries => 119,
  }

  defaults.each do |k,v|
    it "defaults #{k} => #{v}" do
      expect(wait_for[k]).to eq v
    end
  end
end
