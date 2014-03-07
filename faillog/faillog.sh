#!/bin/bash

# Usage: faillog CMD ARGS
# 
# Executes CMD with the given ARGS. If the command ends unsuccessfully, faillog
# will print all output from CMD to STDERR. However, if the command ended
# successfully, faillog remains silent.
# This is useful to run cron jobs that produce a lot of output which you want
# to keep for debugging, if the cron job failed.
 
# run command and capture output and return status
OUTPUT=$((set -o pipefail; "$@" 2>&1 1>&3 | tee >(cat - >&2)) 3>&1)
STATUS=$?

# if return status was not 0, print the captured output
if [ $STATUS -ne 0 ]; then
	cat<<-EOF

	----
	Command failed: $@
	Exit code: $STATUS
	Output:
	$OUTPUT
	EOF
fi

# pass the return status back to the shell
exit $STATUS
