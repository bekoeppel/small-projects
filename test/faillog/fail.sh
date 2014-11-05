#!/bin/bash

if [ "$1" == "nofail" ]; then
	echo "Everything is fine"

else
	echo "Something is going wrong on STDOUT"
	sleep 1
	echo "Something is seriously wrong on STDERR" >&2
	sleep 1
	echo "More errors on STDERR" >&2
	sleep 1

	exit 1;
fi
