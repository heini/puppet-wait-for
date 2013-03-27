include wait_for

################################################################################
# All examples are commented out by default.
# Remove the hashes to give them a try.
################################################################################


# Example for Linux: This waits until the sshd service has started.
#
# Remark: You do not need to do this if you use a proper service resource
# to start the service. After all, this is just an example.
# wait_for { 'service sshd status':
#   regex   => '.*is running.*',
#   waitfor => true,
# }

# Example for Windows: This waits until the MySQL5 service has started.
#
# Remark: You do not need to do this if you use a proper service resource
# to start the service. After all, this is just an example.
# wait_for { 'sc query MySQL5':
#   regex   => '.*STATE\s*:\s*4\s*RUNNING.*',
#   waitfor => true,
# }

# This will wait until the command returns with exit code 42. Of course,
# this will never happen for the echo command, so this example will always
# fail. If you replace 42 with 0, it will succeed immediately, without
# waiting.
# wait_for { 'echo foobar':
#   exit_code         => 42,
#     polling_frequency => 0.3,
#   max_retries       => 5,
#   waitfor           => true,
# }

# This is actually illegal because one of regex or exit_code has to be specified.
# wait_for { 'echo abc':
#   waitfor => true,
# }

# This is also illegal because only one of regex or exit_code can be specified.
# wait_for { 'echo xyz':
#   regex     => 'whatever',
#   exit_code => 0,
#   waitfor   => true,
# }
