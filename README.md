puppet-wait-for
===============

A pseudo resource type for puppet that enables you to wait for certain conditions. You can use shell commands to query arbitrary things and either react on the exit code or match the output of the command against a regular expression.

Warning: By using this module you are leaving the pure puppet philosophy - this is not really a resource which's state can updated/kept in synch by puppet. Also, you might be tempted to use this module to work around issues that should be fixed by other means.

That said, there are situations where this might come in handy - for example, when you need to start/stop services in some asynchronous fashion. Puppet's basic assumption is, that when the code to update one resource has finished, then the resource is in the desired state. In the real world, this is not always the case, especially if you are doing a lot of things via exec resources.

Installation
------------

Go to your puppet modules folder and do

    git clone git@github.com:basti1302/puppet-wait-for.git wait_for

It is important that the folder where this module resisdes is named wait_for, not puppet-wait-for.

Usage
-----

    include wait_for

    # This waits until the Jenkins service has started.
    #
    # Remark 1: This example is actually Windows, just because my current use
    # case is Puppet on Windows. Should work on Linux as well, of course with
    # with a different query command and a different regex.
    # Remark 2: You do not need to do this if you use a proper service resource
    # to start the service. After all, this is just an example.
    #
    wait_for { 'sc query Jenkins':
      regex             => '.*STATE\s*:\s*4\s*RUNNING.*',
      waitfor           => true,
    }

    # This will wait until the command returns with exit code 42. Of course,
    # this will never happen for the echo command, so this example will always
    # fail. If you replace 42 with 0, it will succeed immediately, without
    # waiting.
    wait_for { 'echo foobar':
      exit_code         => 42,
      polling_frequency => 0.3,
      max_retries       => 5,
      waitfor           => true,
    }

    # This is actually illegal because one of regex or exit_code has to be specified 
    # wait_for { 'echo abc':
    #   waitfor           => true,
    # }

    # This is also illegal because only one of regex or exit_code can be specified 
    # wait_for { 'echo xyz':
    #   regex             => 'whatever',
    #   exit_code         => 0,
    #   waitfor           => true,
    # }
