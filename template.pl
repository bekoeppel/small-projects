#!/usr/bin/perl

use strict;
use warnings;

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

use Getopt::Long qw(HelpMessage :config no_ignore_case);
use Pod::Usage;

# variables for command line options
my $commandline;
my $optionstring;

# parse command line options
GetOptions(
	# display brief help
	'H|?|help|usage'	=> sub { HelpMessage(-verbose => 1) },
	
	# display complete help as man page
	'm|man'			=> sub { HelpMessage(-verbose => 2) },

	# command line switch (true or false)
	'c|commandline'		=> \$commandline,
	
	# a string parameter
	'o|optionstring=s'	=> \$optionstring
) or pod2usage( -verbose => 1, -msg => 'Invalid option', -exitval => 1);

# check for mandatory command line options
if ( !defined $optionstring ) {
	pod2usage(-verbose => 1,
		  -msg => '-o|--optionstring parameter is mandatory',
		  -exitval => 1);
}

# the fun begins here (i.e. your code :-) )

# $commandline is now set to true (1) if the -c or --commandline option was passed on the command line
# $optionstring now holds the argument that was passed after the -o or --optionstring parameter
