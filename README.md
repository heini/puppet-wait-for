# puppet-wait-for

[![Build Status](https://img.shields.io/travis/heini/puppet-wait-for.svg)](https://travis-ci.org/heini/puppet-wait-for)

A Puppet resource type that enables you to either wait for certain amount of time or certain conditions, like
- shell commands to query arbitrary things and either react on the exit code or match the output of the command against a regular expression, or
- files or directories to (dis-)appear (new in 3.0)

Warning: By using this module you are leaving the purist Puppet philosophy - this is not really a resource whose state can updated/kept in sync by Puppet. Also, you might be tempted to use this module to work around issues that should be fixed by other means.

That said, there are situations where this might come in handy - for example, when you need to start/stop services in some asynchronous fashion. Puppet's basic assumption is, that when the code to update a resource has finished, then the resource is in the desired state, period. In the real world, this is not always the case, especially if you are doing a lot of things via exec resources and even more if the exec command forks or kicks off a process which needs some time to come up.

## Installation

Either install the latest release from puppet forge:

```text
puppet module install heini-wait_for
```

Or add to your Puppetfile:

```text
mod 'heini/wait_for'
```

## Migrating to version 3.x

With the addition of waiting for files/directories, it doesn't make sense anymore for "query" to be the namevar, which means it must from now on be explicitely provided. For example, instead of writing

```puppet
wait_for { 'command':
  exit_code => 0,
  ...
}
```
one should now write

```puppet
wait_for { 'command_returns_0':
  query     => 'command',
  exit_code => 0,
  ...
}
```

## Usage

Simply add this module to your Puppetfile to make the type available.

## Examples

Wait for a Linux sshd service to start:

```puppet
service { 'logstash':
  ensure => running,
  enable => true,
}

# Wait for the service to really start.
wait_for { 'logstash':
  query             => 'cat /var/log/logstash/logstash-plain.log 2> /dev/null',
  regex             => 'Successfully started Logstash API endpoint',
  polling_frequency => 5,  # Wait up to 2 minutes (24 * 5 seconds).
  max_retries       => 24,
  refreshonly       => true,
}
```

Wait for a Windows MySQL service to start:

```puppet
wait_for { 'MySQL service running':
  query => 'sc query MySQL5',
  regex => '.*STATE\s*:\s*4\s*RUNNING.*',
}
```

Wait until a command returns an exit code of 5:

```puppet
wait_for { 'Copy to remote host':
  query             => 'scp big_file user@remote.com:/tmp',
  exit_code         => 5,   # Handle exit code 5, connection lost.
  polling_frequency => 0.3,
  max_retries       => 5,
}
```

Just wait for 1 minute:

```puppet
wait_for { 'a_minute':
  seconds => 60,
}
```

Execute a command and inject some environment variables (just like 'exec' does).

```puppet
wait_for { 'FOO is set':
  query       => 'env',
  environment => ['FOO=bar', 'BAR=baz'],
  regex       => 'FOO=.*',
}
```

Wait for a file/directory to (dis-)appear
```puppet
wait_for { 'some_new_file':
  path  => '/tmp/foo',
  state => file,   # or present, absent or directory
}
```

## Testing

### Testing

Make sure you have:

* rake
* bundler
* Vagrant (for the Beaker tests)

Install the necessary gems:

```text
bundle install
```

To run the tests from the root of the source code:

```text
bundle exec rake spec
```

To also run the acceptance tests:

```text
export BEAKER_PUPPET_COLLECTION=puppet7
export BEAKER_PUPPET_INSTALL_VERSION=7.32.1
bundle exec rspec spec/acceptance
```

Tested using Puppet 7.32.1, 8.8.1 and Ruby 3.1.4.

### Release

This module uses Puppet Blacksmith to publish to the Puppet Forge.

Ensure you have these lines in `~/.bash_profile`:

```text
export BLACKSMITH_FORGE_URL=https://forgeapi.puppetlabs.com
export BLACKSMITH_FORGE_USERNAME=xxxxx
export BLACKSMITH_FORGE_PASSWORD=xxxxxxxxx
```

Build the module:

```text
bundle exec rake build
```

Push to Forge:

```text
bundle exec rake module:push
```

Clean the pkg dir (otherwise Blacksmith will try to push old copies to Forge next time you run it and it will fail):

```text
bundle exec rake module:clean
```
