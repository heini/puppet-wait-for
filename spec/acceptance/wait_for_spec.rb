require 'spec_helper_acceptance'

describe 'wait_for' do
  it 'should wait for a second' do
    pp = <<~EOF
      wait_for { 'a_second':
        seconds => 1,
      }
    EOF
    expect(apply_manifest(pp).exit_code).to be_zero
  end

  it 'should successfully find foo' do
    pp = <<~EOF
      wait_for { 'echo foo':
        regex => 'foo',
      }
    EOF
    expect(apply_manifest(pp).exit_code).to be_zero
  end

  it 'should successfully find foo with explicit query' do
    pp = <<~EOF
      wait_for { 'foo':
        query => 'echo foo',
        regex => 'foo',
      }
    EOF
    expect(apply_manifest(pp).exit_code).to be_zero
  end

  it 'should error out after max_retries if regex never matches' do
    pp = <<~EOF
      wait_for { 'unicorns':
        query             => 'cat /var/log/messages',
        regex             => 'I am a pattern that should never be seen in /var/log/messages',
        polling_frequency => 5,
        max_retries       => 2,
      }
    EOF
    expect(apply_manifest(pp, :expect_failures => true).stderr).to match(/Did not match regex after max_retries/)
  end

  it 'should error out after max_retries if exit code is wrong' do
    pp = <<~EOF
      wait_for { '/usr/bin/false':
        exit_code         => 2,
        polling_frequency => 0.3,
        max_retries       => 5,
      }
    EOF
    expect(apply_manifest(pp, :expect_failures => true).stderr).to match(/Exit status 1 after max_retries/)
  end

  it 'should wait on refreshonly' do
    pp = <<~EOF
      $file = '/tmp/a_file_that_will_not_already_exist'

      file { 'test_foo':
        path    => $file,
        content => 'bar',
      }

      wait_for { 'five seconds':
        seconds     => 5,
        refreshonly => true,
        subscribe   => File['test_foo'],
      }
    EOF
    expect(apply_manifest(pp).stdout).to match(/Wait_for.*Triggered 'refresh' from 1 event/)
    expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero # Idempotence - nothing should happen on the second run.
  end

  it 'should not error out after max_retries if exit code is wrong if refreshonly' do
    pp = <<~EOF
      wait_for { '/usr/bin/false':
        exit_code         => 2,
        polling_frequency => 0.3,
        max_retries       => 5,
        refreshonly       => true,
      }
    EOF
    expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero # Nothing should happen.
  end

  it 'should not error out after max_retries if regex never matches if refreshonly' do
    pp = <<~EOF
      wait_for { 'unicorns':
        query             => 'cat /var/log/messages',
        regex             => 'I am a pattern that should never be seen in /var/log/messages',
        polling_frequency => 5,
        max_retries       => 2,
        refreshonly       => true,
      }
    EOF
    expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero
  end

  it 'should inject variables' do
    pp = <<~EOF
      wait_for { 'env':
        environment => ['FOO=bar', 'BAR=baz'],
        regex       => 'FOO=.*',
      }
    EOF
    expect(apply_manifest(pp).exit_code).to be_zero
  end
end
