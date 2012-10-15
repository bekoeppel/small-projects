#!/usr/bin/perl

use strict;
use warnings;

=pod

=for comment This is a POD documentation. The syntax is described here:
http://perldoc.perl.org/perlpod.html. Please note that the blank lines are
required.

=head1 NAME

B<mofn.pl> - split/join a passphrase into/from M-of-N subphrases

=head1 DESCRIPTION

B<mofn.pl> splits a given passphrase into N subphrases, and re-joins
at least M of them back into the initial passphrase. It uses the 
algorithm described in "How to Share a Secret" by Adi Shamir.

=head1 SYNOPSIS

B<mofn.pl> [--help|--man] [--mode I<SPLIT|JOIN>] [-M I<M_SPLITS>] [-N I<N_SPLITS>] [-p|--phrase I<PHRASE> | -p|--phrases I<INDEX>:I<SUBPHRASE>]

=head1 OPTIONS

=over 8

=item B<--help>

Print a brief help message and exit.

=item B<--man>

Print the manual page and exit.

=item B<-m | --mode> I<SPLIT|JOIN>

The operation mode of B<mofn.pl>. The mode can be either I<SPLIT> or I<JOIN>.

If B<--mode> is I<SPLIT>, then the phrase given with the B<-p|--phrase> option is split into I<N_SPLITS> subphrases, 
whereof at least I<M_SPLITS> subphrases are required to recover the initial phrase. In the I<SPLIT> mode, the B<-N> and B<-M> options are mandatory.

If B<--mode> is I<JOIN>, then the subphrases (at least I<M_SPLITS> of them) are joined and recover the initial phrase. The B<-N> and B<-M> options are not
required (and will be ignored if specified). The individual subphrases have to be entered by using the B<-p|--phrases> option multiple times. Note that
the subphrase has to be entered in the format I<INDEX>:I<SUBPHRASE>. Both I<INDEX> and I<SUBPHRASE> where the output of running B<mofn.pl> initially.

=item B<-N> I<N_SPLITS>

The number (N), how many subphrases will be generated. This option only applies when B<--mode> is set to I<SPLIT>.

=item B<-M> I<M_SPLITS>

The number (M), how many subphrases will be required to recover the initial phrase. This option only applies when B<--mode> is set to I<SPLIT>.

=item B<-p | --phrase | --phrases> I<PHRASE> *

The B<-p|--phrase> option with one argument is used in the I<SPLIT> mode. The same option, but specified multiple times is used in the I<JOIN> mode.

In the I<SPLIT> mode, the given I<PHRASE> will be split into I<N_SPLITS> subphrases. From those subphrases, at least I<M_SPLITS> subphrases are required to recover the initial phrase.

In the I<JOIN> mode, the given I<INDEX>:I<SUBPHRASE> pairs recover the initial phrase.

=back

=head1 AUTHOR

Benedikt Koeppel, L<mailto:code@benediktkoeppel.ch>, L<http://benediktkoeppel.ch>

=cut

use Getopt::Long qw(HelpMessage :config no_ignore_case);
use Pod::Usage;
#use Math::MatrixReal;
use PDL;
use PDL::Matrix;
use Data::Dumper;
use PDL::MatrixOps;

# variables for command line options
my $mode;
my $n;
my $m;
my @phrases;
my $debug;

# parse command line options
GetOptions(
	'H|?|help|usage'		=> sub { HelpMessage(-verbose => 1) },
	'man'				=> sub { HelpMessage(-verbose => 2) },
	'm|mode=s'			=> \$mode,
	'N=s'				=> \$n,
	'M=s'				=> \$m,
	'p|phrase|phrases=s@{1,}'	=> \@phrases,
	'd|debug'			=> \$debug
) or pod2usage( -verbose => 1, -msg => 'Invalid option', -exitval => 1);

# check for mandatory command line options
if ( !defined $mode ) {
	pod2usage(-verbose => 1,
		  -msg => '-m|--mode MODE parameter is mandatory',
		  -exitval => 1);
}

if ( $mode eq "SPLIT" ) {

	# SPLIT
	# check for variables
	if ( !defined $n || !defined $m ) {
		pod2usage(-verbose => 1,
			  -msg => '-M and -N are mandatory',
			  -exitval => 1);
	}
	if ( $n < $m ) {
		pod2usage(-verbose => 1,
			  -msg => '-M has to be smaller than -N',
			  -exitval => 1);
	}
	if ( !defined $phrases[0] ) {
		pod2usage(-verbose => 1,
			  -msg => '-p|--phrase parameter is mandatory',
			  -exitval => 1);
	}
	if ( scalar @phrases > 1 ) {
		pod2usage(-verbose => 1,
			  -msg => 'in SPLIT mode, only one phrase can be specified',
			  -exitval => 1);
	}

	# passphrase is string, convert it to a number
	my @chars = split(//,$phrases[0]);
	my $p = 0;
	my $rand_max = 0;
	for(my $i=0; $i<scalar @chars; $i++) {
		my $c = $chars[$i];
		print "$i: ord($c) = " . ord($c) . "\n" if $debug;
		$p += 256**$i*ord($c);
		$rand_max += 256**$i*256;
	}
	print "p: $p\n" if $debug;

	# generate random polynom of degree $m-1
	my @a;
	for(my $i=0; $i<$m-1; $i++) {
		push @a, int(rand($rand_max)+1);
	}
	print "a_i = @a\n" if $debug;

	# evaluate polynom
	for(my $j=1; $j<=$n; $j++) {
		my $y = $p;
		for(my $i=1; $i<$m; $i++) {
			$y += $j**$i * $a[$i-1];
		}

		# print the X and Y values. This is the split secret
		print "$j:$y\n";
	}

} elsif ( $mode eq "JOIN" ) {
	if ( !defined $m ) {
		pod2usage(-verbose => 1,
			  -msg => '-M is mandatory',
			  -exitval => 1);
	}
	if ( scalar @phrases < $m ) {
		pod2usage(-verbose => 1,
			  -msg => 'Not enough subphrases specified. You have to specify M subphrases.',
			  -exitval => 1);
	}

	# two matrices for the expanded X and the Y values
	my $y_mat = mzeroes($m,$m);
	my $x_vect = vzeroes($m);

	# use all given phrases
	for(my $i=0; $i<scalar @phrases; $i++) {
		
		# this phrase is p
		my $p = $phrases[$i];

		# split into X and Y part
		my($y,$x) = split(/:/, $p);

		# store the value in the X vector
		$x_vect->set($i, 0, $x);

		# expand the value into the Y matrix
		for(my $j=0; $j<$m; $j++) {
			$y_mat->set($i, $j, $y**$j);
		}

	}
	print $y_mat if $debug;

	# invert y_mat
	my $y_mat_inv = PDL::MatrixOps::inv $y_mat;
	my $y_mat_inv_trn = $y_mat_inv->transpose();
	print $y_mat_inv_trn if $debug;

	# transpose x_vect (see http://search.cpan.org/~csoe/PDL-2.4.3/Basic/MatrixOps/matrixops.pd#TIPS_ON_MATRIX_OPERATIONS)
	my $x_vect_trn = $x_vect->transpose();
	print $x_vect_trn if $debug;

	# multiply by x_vect
	my $a_mat = $y_mat_inv_trn x $x_vect_trn;
	print $a_mat if $debug;

	# a[0] is the recovered phrase
	my $p = $a_mat->at(0,0);
	print "$p\n" if $debug;

	# convert it back to a string
	do {
		print chr($p & 255);
	} while ( ($p = $p>>8) != 0 );
	print "\n";






} else {
pod2usage(-verbose => 1,
	  -msg => "-m|-mode $mode is not a valid mode.",
	  -exitval => 1);
}

