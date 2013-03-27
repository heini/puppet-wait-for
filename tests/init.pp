include wait_for

# All examples are commented out by default.
# Remove the hashes to give them a try.

# this waits until the Jenkins service has started
# wait_for { 'sc query Jenkins':
#   regex             => '.*STATE\s*:\s*4\s*RUNNING.*',
#   waitfor           => true,
# }

# this will fail because echo always has exit code 0
# wait_for { 'echo foobar':
#   exit_code         => 42,
#   polling_frequency => 0.3,
#   max_retries       => 5,
#   waitfor           => true,
# }

# this is actually illegal because one of regex or exit_code has to be specified 
# wait_for { 'echo abc':
#   waitfor           => true,
# }

# this is actually illegal because only one of regex or exit_code can be specified 
# wait_for { 'echo xyz':
  # regex             => 'whatever',
  # exit_code         => 0,
  # waitfor           => true,
  # }
