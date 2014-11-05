#!/bin/bash

# Faillog
# =======
# 
# Usage: faillog CMD ARGS
# 
# Executes a script and captures the script's output. If the script ends
# successfully, the output is silently discarded. If the script exits with a
# code != 0, the output is printed to STDOUT. This makes it possible to run
# verbose scripts, but only retain the output if the script failed.
# 
# Executes CMD with the given ARGS. If the command ends unsuccessfully, faillog
# will print all output from CMD to STDERR. However, if the command ended
# successfully, faillog remains silent.
# This is useful to run cron jobs that produce a lot of output which you want
# to keep for debugging, if the cron job failed.
# 
# Examples:
# ./fail.sh
# 	demo script, which will print a few lines to STDOUT and STDERR and
# 	return with exit code 1 (failure)
# 
# ./fail.sh nofail
# 	the same demo script, but it will exit with code 0 (success)
# 
# ./faillog.sh ./fail.sh
# 	will run `./fail.sh` (see above). Because the script fails, faillog
# 	will print it's output
# 
# ./faillog.sh ./fail.sh nofail
# 	will run `./fail.sh nofail`, which is successful. All output is
# 	discarded
 
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
