#!/bin/bash

# CONFIG
# the mindmap
WATCHFILE=~/private/documents/Dashboard.mm
# script to run, when WATCHFILE was changed
EXECSCRIPT=~/Applications/refresh-mm-to-dropbox.sh

# Make sure it runs only once
SCRIPTNAME=`basename $0`
PIDFILE=~/.${SCRIPTNAME}.pid

if [ -f ${PIDFILE} ]; then
	#verify if the process is actually still running under this pid
	OLDPID=`cat ${PIDFILE}`
	RESULT=`ps -ef | grep "${OLDPID}" | grep "${SCRIPTNAME}"`  

	if [ -n "${RESULT}" ]; then
		#echo "Script already running! Exiting"
		exit 255
	fi

fi

function watchfile {
	#grab pid of this process and update the pid file with it
	PID=`ps -ef | grep ${SCRIPTNAME} | head -n1 |  awk ' {print $2;} '`
	echo ${PID} > ${PIDFILE}

	#echo "watching $WATCHFILE for modifications"

	while true;
	do
		inotifywait -e modify $WATCHFILE 1>/dev/null 2>&1
		$EXECSCRIPT
	done

	rm $PIDFILE
}

watchfile &
exit
