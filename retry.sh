#!/bin/bash

# retry.sh NUM_RETRIES INTERVAL CMD ARGS
#
# Executes CMD with ARGS until the return code is zero. If the return code is not zero,
# the command is executed again after INTERVAL seconds, for at most NUM_RETRIES times.

if [ $# -lt 3 ]; then
	echo "Usage: retry.sh NUM_RETRIES INTERVAL CMD [ARGS]" >&2
	exit 1;
fi

NUM_RETRIES=$1
re='^[0-9]+$'
if ! [[ $NUM_RETRIES =~ $re ]]; then
	echo "NUM_RETRIES should be a number (was $NUM_RETRIES)" >&2
	echo "Usage: retry.sh NUM_RETRIES INTERVAL CMD [ARGS]" >&2
	exit 1;
fi
shift

INTERVAL=$1
if ! [[ $INTERVAL =~ $re ]]; then
	echo "INTERVAL should be a number (was $INTERVAL)" >&2
	echo "Usage: retry.sh NUM_RETRIES INTERVAL CMD [ARGS]" >&2
	exit 1;
fi
shift

for (( i=1; i<=$NUM_RETRIES; i++ )); do

	# execute command and get return code
	echo "Executing $@ (attempt $i)"
	$@
	STATUS=$?

	# successfully executed $@, exit
	if [ $STATUS -eq 0 ]; then
		exit;

	# execution failed
	else
		# still at least one retry left
		if [ $i -lt $NUM_RETRIES ]; then
			echo "Status was $STATUS, executing again in $INTERVAL seconds"
			sleep $INTERVAL
			echo ""

		# last try, failing
		else
			echo "Status was $STATUS, not executing again"
			exit $STATUS
		fi
	fi
done
