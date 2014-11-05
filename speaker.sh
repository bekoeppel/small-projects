#!/bin/bash

if [[ "$1" == "" ]]; then
	echo "Usage: speaker [mute|unmute|toggle|xx%]"
elif [[ $1 == "mute" ]]; then
	amixer -c 0 sset Master,0 mute
	amixer -c 0 sset Headphone,0 mute
elif [[ $1 == "unmute" ]]; then
	amixer -c 0 sset Master,0 unmute
	amixer -c 0 sset Headphone,0 unmute
elif [[ $1 == "toggle" ]]; then
	
	amixer get Headphone | grep '\[on\]' 1>/dev/null 2>&1
	if [ $? -eq 0 ]; then
		amixer -c 0 sset Master,0 mute
		amixer -c 0 sset Headphone,0 mute
	else
		amixer -c 0 sset Master,0 unmute
		amixer -c 0 sset Headphone,0 unmute
	fi

else
	amixer -c 0 sset Master,0 $1
	amixer -c 0 sset Headphone,0 $1
fi

I3PID=$(pgrep i3status);
if [[ "$I3PID" != "" ]]; then
	kill -SIGUSR1 $I3PID
fi
