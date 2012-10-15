#!/usr/bin/perl

use 5.010;
use Getopt::Std;
use utf8;
use URI::Escape;
binmode STDOUT, ":utf8";


# -a: also print the archive (daily journal)
# -w: make wiki output
# -i <number>: set the number of indents
getopts('awi:');

my $indent;
if ( $opt_i > 1 ) {
	$indent = " " x $opt_i;
} else {
	$indent = " ";
}


sub print_indent {
	if ( $opt_w ) {
		# make wiki output
		if ( $_[0] >= 1 ) {
			print $indent x ($_[0]-1) , "  * ";
		}
	} else {	
		print $indent x $_[0];
		$_ = $_[1];
		# replace HTML escaped UTF-8 characters
		s/&#x([0-9A-fa-f]*);/chr hex $1/ge;
		print join("\r\n" . $indent x $_[0] . " \\- ", split(/\n/, $_));
	}	
}


my $depth = 0;
my $in_archive = 0;
my $skipped_lines = 0;
while(<STDIN>) {
	if ( $_ =~ /<node[^>]*TEXT="(.*?)"[^>]*">/ ) {
		# if the archive should be omitted ($opt_a is set), then we store the current depth
		# and don't print the daily journal (archive)
		if ( !$opt_a && ( 
				1 == 2	# just to make the next few lines look generic
				|| ( $1 =~ /^(meta mindmap)$/ && $depth == 1 )
				|| ( $1 =~ /^(daily journal)$/ && $depth == 1 ) 
				|| ( $1 =~ /^(knowledgebase)$/ && $depth == 1 )
				|| ( $1 =~ /^(incubator)$/ && $depth == 1)
			) 
		) {	
			$in_archive = $depth;
			print_indent($depth, $1);
			print " (skipped";	# this line does not have a \r\n, it will be printed once we leave the archive and know how many lines were printed
			$depth++;
		} else {
			#print "1: ";
			#print $indent x $depth;
			if(!$opt_a && $in_archive) {
				# if we are in the archive, and have asked not to print it, then don't do it :-)
				$depth++;
				$skipped_lines++;
				next;
			}
			print_indent($depth, $1);
			print "\r\n";	# TODO: instead, print each line individually and make sure it is correctly indented
			$depth++;
		}
	} elsif ( $_ =~ /<node[^>]*TEXT="(.*?)"[^>]*\/>/ ) {
		#print "2: ";
		#print $indent x $depth;
		if(!$opt_a && $in_archive) {
			# if we are in the archive, and have asked not to print it, then don't do it :-)
			$skipped_lines++;
			next;
		}
		print_indent($depth, $1);	# TODO: instead, print each line individually and make sure it is correctly indented
		print "\r\n";
	} elsif ( $_ =~ /<\/node>/ ) {
		#print "3: \r\n";
		$depth--;
		# we are coming out (up) of the tree. If we are at the same level as where we started omitting the archive (daily journal), we have left the archive
		if ( !$opt_a && $in_archive != 0 && $depth <= $in_archive ) {
			$in_archive = 0;
			print " $skipped_lines lines)\r\n";
			$skipped_lines = 0;
		}
	}
}
