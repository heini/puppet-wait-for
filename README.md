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
