#!/bin/bash

# POD documentation
: <<=cut
=pod

=for comment This is a POD documentation. The syntax is described here:
http://perldoc.perl.org/perlpod.html. Please note that the blank lines are
required.

=head1 NAME

B<your_script> - with a 5 word description

=head1 DESCRIPTION

B<your_script> with a longer description, what the script does and for which
purpose it is intended.

=head1 SYNOPSIS

B<your_script> [--help|--man] [-c|--commandline] [-o|--optionstring I<with_parameters>]

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
# Mac OS X `getopt` does not support long options and is broken badly.
SHORTOPTS="hmco:"
LONGOPTS="help man commandline optionstring:"
if [ "$(getopt -V | grep getopt >/dev/null; echo $?)" -ne 0 ]
then
	# Non-GNU, only short options
	GETOPT_OPT=$(getopt $SHORTOPTS $*) || usage
else
	# GNU, support for long options
	GETOPT_OPT=$(getopt -n"$0" -a --longoptions="$LONGOPTS" "$SHORTOPTS" "$@") || usage
fi
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
