#!/usr/bin/perl

use strict;
use warnings;

use Date::Calc qw(Day_of_Week check_date);

=pod

=for comment This is a POD documentation. The syntax is described here:
http://perldoc.perl.org/perlpod.html. Please note that the blank lines are
required.

=head1 NAME

B<mindmap-date-generator> - generate dates to be used in my FreeMind Dashboard

=head1 DESCRIPTION

B<mindmap-date-generator> generates dates for a whole month, which can be easily
copied into my Dashboard Mindmap.

=head1 SYNOPSIS

B<mindmap-date-generator> [--help|--man] [-m|--month I<MONTH>] [-y|--year I<YEAR>]

=head1 OPTIONS

=over 8

=item B<--help>

Print a brief help message and exit.

=item B<--man>

Print the manual page and exit.

=item B<-m | --month> I<MONTH>

The number of the month for which dates should be generated. If omitted, then the
next month is assumed.

=item B<-y | --year> I<YEAR>

The year for which dates should be generated. If omitted, then the year of the following
month is assumed. 

=back

=head1 AUTHOR

Benedikt Koeppel, L<mailto:code@benediktkoeppel.ch>, L<http://benediktkoeppel.ch>

=cut

use Getopt::Long qw(HelpMessage :config no_ignore_case);
use Pod::Usage;

# fixed
my @DOW=('Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So');

# variables for command line options
my $month;
my $year;

# parse command line options
GetOptions(
	'H|?|help|usage'	=> sub { HelpMessage(-verbose => 1) },
	'man'			=> sub { HelpMessage(-verbose => 2) },
	'm|month=s'		=> \$month,
	'y|year=s'		=> \$year
) or pod2usage( -verbose => 1, -msg => 'Invalid option', -exitval => 1);

my @localtime = localtime(time);
if ( !defined $month ) {
	$month=$localtime[4]+2;	# +1 because the months in Perl start at 0, and +1 for the next month
}
if ( !defined $year ) {
	$year=$localtime[5]+1900;
	if ($month == 12) {
		$year += 1;
	}
}
if ( $year < 100 ) {
	$year += 2000;
}


# start with the 1st of the month
my $day = 1;
do {
	# calculate the day of the week
	my $dow = $DOW[ Day_of_Week($year, $month, $day)-1 ];

	# print yyyy-mm-dd dow
	printf("%04d-%02d-%02d %s\n", $year, $month, $day, $dow);

	# then add 1 to the date
	$day += 1;

	# if the month is still the same, repeat
} while ( check_date($year, $month, $day) )
