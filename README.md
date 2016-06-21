puppet-wait-for
===============

A pseudo resource type for puppet that enables you to wait for certain conditions. You can use shell commands to query arbitrary things and either react on the exit code or match the output of the command against a regular expression.

Warning: By using this module you are leaving the pure puppet philosophy - this is not really a resource which's state can updated/kept in synch by puppet. Also, you might be tempted to use this module to work around issues that should be fixed by other means.

That said, there are situations where this might come in handy - for example, when you need to start/stop services in some asynchronous fashion. Puppet's basic assumption is, that when the code to update a resource has finished, then the resource is in the desired state, period. In the real world, this is not always the case, especially if you are doing a lot of things via exec resources and even more if the exec commandforks or kicks off a process which needs some time to come up.

Installation
------------

Either install the latest release from puppet forge:

    puppet module install basti1302-wait_for

or install the current head from the git repository by going to your puppet modules folder and do

    git clone git@github.com:basti1302/puppet-wait-for.git wait_for

It is important that the folder where this module resisdes is named wait_for, not puppet-wait-for.

Usage
-----

    include wait_for

    # Example for Linux: This waits until the sshd service has started.
    #
    # Remark: You do not need to do this if you use a proper service resource
    # to start the service. After all, this is just an example.
    wait_for { 'service sshd status':
      regex    => '.*is running.*',
    }

    # Example for Windows: This waits until the MySQL5 service has started.
    #
    # Remark: You do not need to do this if you use a proper service resource
    # to start the service. After all, this is just an example.
    wait_for { 'sc query MySQL5':
      regex   => '.*STATE\s*:\s*4\s*RUNNING.*',
    }

    # This will wait until the command returns with exit code 42. Of course,
    # this will never happen for the echo command, so this example will always
    # fail. If you replace 42 with 0, it will succeed immediately, without
    # waiting.
    wait_for { 'echo foobar':
      exit_code         => 42,
      polling_frequency => 0.3,
      max_retries       => 5,
    }

    # This will simply wait for one minute
    wait_for { 'a_minute':
      seconds => 60,
    }
    
    # This will execute a command and inject some environment variables (just like 'exec' does).
    wait_for { 'env':
      environment => ['FOO=bar', 'BAR=baz'],
      regex       => 'FOO=.*',
    }

    # This is actually illegal because one of regex or exit_code has to be specified.
    # wait_for { 'echo abc':
    # }

    # This is also illegal because only one of regex or exit_code can be specified.
    # wait_for { 'echo xyz':
    #   regex             => 'whatever',
    #   exit_code         => 0,
    # }

    # The name of the namevar (which is the command to query the current state) is query, by the way.
    wait_for { 'without implicit namevar':
      query   => 'echo foobar',
      regex   => 'foobar',
    }
