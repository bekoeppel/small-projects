#!/bin/bash

# POD documentation
: <<=cut
=pod

=head1 NAME

B<center_windows.sh> - center all off-screen windows

=head1 DESCRIPTION

B<center_windows.sh> will center all off-screen windows. This is particularly useful
if you switch from a dual-monitor to a single-monitor setup. 

=head1 SYNOPSIS

B<center_windows.sh> [--help|--man] [-c|--commandline] [-o|--optionstring I<with_parameters>]

=head1 OPTIONS

=over 8

=item Document all command line options, each with a separate C<=item>.

=item B<--help>

Print a brief help message and exit.

=item B<--man>

Print the manual page and exit.

=item B<-c | --commandline>

Description what the B<--commandline> switch does.

=item B<-o | --optionstring> I<with_parameters>

Description what the B<--optionstring> parameter does, and what the user should
provide for the I<with_parameters> argument.

=back

=head1 AUTHOR

Benedikt Koeppel, L<mailto:code@benediktkoeppel.ch>, L<http://benediktkoeppel.ch>

=cut

# automatically print usage and man page
usage() { pod2usage -verbose 1 $0; exit 1; }
man()   { pod2usage -verbose 2 $0; exit 1; }

# option parsing
# options can be a switch (i.e. true/false), or they can have an argument, e.g.
# in '--optionstring XYZ', 'XYZ' is the argument for the --optionstring option.
# options that require an argument are followed by a colon
# add short options here: -----------------------------------------------------\
# add long options here: -----------------v (separated by a space)             V
GETOPT_OPT=`getopt -n$0 -a --longoptions="help man commandline optionstring:" "hmco:" "$@"` || usage
set -- $GETOPT_OPT
[ $# -eq 0 ] && usage

while [ $# -gt 0 ]
do
	case "$1" in
		# add parsing of your options here. If the option has an
		# argument, then use 'shift;;' at the end, otherwise just ';;'
		-h|--help)		usage;;			# -h/--help, print usage
		-m|--man)		man;;			# -m/--man, print the man page
		-c|--commandline)	COMMANDLINE=1;;		# -c/--commandline option passed, set $COMMANDLINE to true (1)
		-o|--optionstring)	OPTIONSTRING=$2;shift;;	# -o/--optionstring option, $2 holds the parameter. Store it to $OPTIONSTRING variable
		--)			shift;break;;		# this was the last option to process
		-*)			usage;;			# unknown option, print usage
		*)			break;;			# anything unexpected
	esac
	shift
done

# the fun begins here (i.e. your code :-) )

# $COMMANDLINE is now set to true (1) if the -c or --commandline option was passed on the command line
# $OPTIONSTRING now holds the argument that was passed after the -o or --optionstring parameter

# find display dimensions
disp_x=$(xdpyinfo | grep dimensions | awk '{print $2}' | tr 'x' '\t' | awk '{print $1}')
disp_y=$(xdpyinfo | grep dimensions | awk '{print $2}' | tr 'x' '\t' | awk '{print $2}')

xdotool search --all '.*' | while read windowid
do
	winname=$(xwininfo -id $windowid | head -n 2 | tail -n 1 | sed 's/xwininfo: Window id: [^\"]*//')
	x_pos=$(xwininfo -id $windowid | grep 'Absolute upper-left X' | awk '{print $4}')
	y_pos=$(xwininfo -id $windowid | grep 'Absolute upper-left Y' | awk '{print $4}')
	width=$(xwininfo -id $windowid | grep 'Width' | awk '{print $2}')
	height=$(xwininfo -id $windowid | grep 'Height' | awk '{print $2}')
	
	# determine new 
	new_x="undef"
	move=""
	if [ $x_pos -ge $disp_x ]; then
		new_x=$(($x_pos-disp_x))
		move="left "
	else
		new_x=$x_pos
	fi
	new_y="undef"
	if [ $y_pos -ge $disp_y ]; then
		new_y=$(($y_pos-disp_y))
		move="$moveup"
	else
		new_y=$y_pos
	fi

	echo "$windowid, $winname, x:$x_pos, y:$y_pos, w:$width, h:$height, $move, ->x:$new_x, ->y:$new_y"
	if [[ "$move" == "" ]]; then
		echo "not moving"
	else
		echo "moving $windowid to $new_x $new_y"
		xdotool windowmove $windowid $new_x $new_y
	fi

done
