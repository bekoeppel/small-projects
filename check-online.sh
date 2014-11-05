#!/bin/bash

# POD documentation
: <<=cut
=pod

=head1 NAME

B<check-online.sh> - checks if device is online

=head1 DESCRIPTION

B<check-online.sh> with a longer description, what the script does and for which
purpose it is intended.

=head1 SYNOPSIS

B<check-online.sh> [--help|--man] [-s|--summary]

=head1 OPTIONS

=over 8

=item B<--help>

Print a brief help message and exit.

=item B<--man>

Print the manual page and exit.

=item B<-s | --summary>

Print only summary output.

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
# add short options here: -----------------------------------\
# add long options here: -----------------v (separated by a space)
GETOPT_OPT=`getopt -n$0 -a --longoptions="help man summary" "hms" "$@"` || usage
set -- $GETOPT_OPT
[ $# -eq 0 ] && usage

while [ $# -gt 0 ]
do
	case "$1" in
		# add parsing of your options here. If the option has an
		# argument, then use 'shift;;' at the end, otherwise just ';;'
		-h|--help)		usage;;			# -h/--help, print usage
		-m|--man)		man;;			# -m/--man, print the man page
		-s|--summary)		SUMMARY=1;;		# -c/--commandline option passed, set $COMMANDLINE to true (1)
		--)			shift;break;;		# this was the last option to process
		-*)			usage;;			# unknown option, print usage
		*)			break;;			# anything unexpected
	esac
	shift
done


OUTPUT_L=""
OUTPUT_S=""

# ping 8.8.8.8 to see if IP works
echo "Pinging..."
PING_OUTPUT=$(ping -W 0.2 -w 1 -i 0.2 8.8.8.8 2>&1 | tee /dev/tty)
echo $PING_OUTPUT | grep '0% packet loss' >/dev/null
if [ $(echo $?) == "0" ]; then
	
	# has returned 0% packet loss
	OUTPUT_L="IP: up"
	OUTPUT_S="^"
else

	# has not returned 0% packet loss
	OUTPUT_L="IP: down"
	OUTPUT_S="v"
fi
echo

# resolve google-public-dns-a.google.com
echo "DNS resolving..."
DNS_OUTPUT=$(host google-public-dns-a.google.com 2>&1 | tee /dev/tty)
echo $DNS_OUPTUT | grep -v 'NXDOMAIN' >/dev/null
if [ $(echo $?) == "0" ]; then

	# has not returned NXDOMAIN
	OUTPUT_L="${OUTPUT_L} | DNS: up"
	OUTPUT_S="${OUTPUT_S}^"
else

	# has returned NXDOMAIN
	OUTPUT_L="${OUTPUT_L} | DNS: down"
	OUTPUT_S="${OUTPUT_S}v"
fi
echo

# print output
if [ "$SUMMARY" == "1" ]; then
	echo $OUTPUT_S
else
	echo $OUTPUT_L
fi
