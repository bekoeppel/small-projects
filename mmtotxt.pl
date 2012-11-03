#!/usr/bin/perl

use strict;
use warnings;

use XML::LibXML;
use Data::Dumper;
use utf8;
use Getopt::Long qw(GetOptions HelpMessage VersionMessage :config no_ignore_case);
use Pod::Usage;
use File::stat;
binmode STDOUT, ":utf8";

# configuration
my %opts;
GetOptions(
	'h|H|help|usage|?'	=> sub { HelpMessage(-verbose => 1) },
	'man'			=> sub { HelpMessage(-verbose => 2) },
	'f|file|infile|input=s' => \$opts{'infile'},
	'o|outfile|output=s'    => \$opts{'outfile'},
	'appointments|ical'	=> \$opts{'appointments'},
	'i|indent=s'            => \$opts{'spaces_per_indent'},
	'N|newline'             => \$opts{'split_newlines'},
	'ns|separator=s'        => \$opts{'newline_separator'},
	'L|links'               => \$opts{'print_links'},
	'I|icons'               => \$opts{'print_icons'},
	'A|attributes'          => \$opts{'print_attributes'},
	'F|formula'             => \$opts{'print_formula'},
	'C|connectors'          => \$opts{'print_connectors'},
	't|truncate=s@{1,}'     => \@{$opts{'truncate_pattern'}},
	'a|age=s'		=> \$opts{'min_age'},
	'r|root=s'		=> \$opts{'root'},
	'j|join-newlines'	=> \$opts{'join_newlines'},
	'w|whole-path'		=> \$opts{'whole_path'}
) or HelpMessage(-verbose => 1);

# print help if requested
@ARGV=();

# read a file if -f was specified, otherwise read from STDIN
my $doc;
if (defined $opts{'infile'}) {
	$doc = XML::LibXML->load_xml(location => $opts{'infile'});
} else {
	my $input;
	while(<>) {
		chomp;
		$input .= $_;
	}
	$doc = XML::LibXML->load_xml(string => $input);
}
my $root = $doc->documentElement();

# check if the output file is older than min_age (only if we don't print to STDOUT)
if (defined $opts{'outfile'} && defined $opts{'min_age'} && -f $opts{'outfile'} ) {
	my $stat = stat($opts{'outfile'});
	my $mtime = $stat->mtime;
	my $now = time;
	if ($mtime >= $now - $opts{'min_age'}) {
		print STDERR "$opts{'outfile'} was written " . ($now-$mtime) . " seconds ago. Not refreshing until it is at least $opts{'min_age'} seconds old.\n";
		exit;
	}
}

# print to a file if -o was specified, otherwise to STDOUT
if (defined $opts{'outfile'}) {
	open OUTFILE, ">$opts{'outfile'}" or die "can't open $opts{'outfile'}: $!";
} else {
	open OUTFILE, ">-";
}
binmode OUTFILE, ":utf8";

# define the number of spaces per indent
if (!defined $opts{'spaces_per_indent'}) {
	$opts{'spaces_per_indent'} = 4;
}

# define the newline separator
if (!defined $opts{'newline_separator'}) {
	$opts{'newline_separator'} = " \\- ";
}







# get a list of all target nodes
# if we encounter a node which is in the linktargets list, then print also the ID (so that the source of the link can say "see also node ID_xxx")
my %linktargets;
if ($opts{'print_connectors'}) {
	foreach my $link ($root->getElementsByTagName("arrowlink")) {
		push @{ $linktargets{$link->getAttribute("DESTINATION")} }, $link->parentNode->getAttribute("ID");
	}
}

# recurse, then print the whole tree out
print OUTFILE recurse("", $root, 0);

# recurse through the whole tree of nodes. The whole tree is returned as one text
sub recurse {
	my $parent = shift;
	my $this = shift;
	my $level = shift;

	my $complete_output = "";

	foreach my $node ($this->getChildrenByTagName("node")) {

		# build the final output
		my $output;

		# indent depends on the depth (level)
		my $indent = " " x ($level*$opts{'spaces_per_indent'});
		my $newline_separator;
		if ( defined $opts{'join_newlines'} ) {
			$newline_separator = $opts{'newline_separator'};
		} else {
			$newline_separator = "\r\n" . $indent . $opts{'newline_separator'};
		}
		$output .= $indent;

		# the node ID
		my $nodeid = $node->getAttribute("ID");

		# prepend the whole path (i.e. the parent) if the wholepath option was specified
		if ($opts{'whole_path'}) {
			$output .= "$parent/";
		}

		# the TEXT attribute holds the visible text. Newlines need to be replaced by newlines *and* the proper indent, and a " \- " marker to signalize the multiline node
		my $text = $node->getAttribute("TEXT");
		if ($opts{'split_newlines'}) {
			$output .= join($newline_separator, split(/\n/, $text));
		} else {
			$output .= $text;
		}

		# the LINK attribute holds the external links (URL). If LINK and TEXT are the same, then don't print the LINK
		if ($opts{'print_links'}) {
			my $link = $node->getAttribute("LINK");
			if (defined $link && $link ne "" && $link ne $text) {
				$output .= " (LINK: $link)";
			}
		}
		
		# the child <icon> elements define this node's icons
		if ($opts{'print_icons'}) {
			my @icons = $node->getChildrenByTagName("icon");
			my @texticons;
			foreach my $icon (@icons) {
				push @texticons, $icon->getAttribute("BUILTIN");
			}
			if (@texticons == 1) {
				$output .= " (ICON: ";
				$output .= $texticons[0];
				$output .= ")";
			} elsif (@texticons > 1) {
				$output .= " (ICONS: ";
				$output .= join(", ", @texticons);
				$output .= ")";
			}
		}

		# attributes are stored in <attribute> child nodes
		if ($opts{'print_attributes'}) {
			my @attributes = $node->getChildrenByTagName("attribute");
			my @textattributes;
			foreach my $attribute (@attributes) {
				push @textattributes, $attribute->getAttribute("NAME") . ":" . $attribute->getAttribute("VALUE");
			}
			if (@textattributes == 1) {
				$output .= " (ATTRIBUTE: ";
				$output .= $textattributes[0];
				$output .= ")";
			} elsif (@textattributes > 1) {
				$output .= " (ATTRIBUTES: ";
				$output .= join($newline_separator, @textattributes);
				$output .= ")";
			}
		}

		# LaTeX formulas are stored in <hook EQUATION=...> child nodes
		if ($opts{'print_formula'}) {
			my @hooks = $node->getChildrenByTagName("hook");
			my @texthooks;
			foreach my $hook (@hooks) {
				if ($hook->hasAttribute("EQUATION")) {
					push @texthooks, $hook->getAttribute("EQUATION");
				}
			}
			if (@texthooks == 1) {
				$output .= " (EQUATION: ";
				$output .= $texthooks[0];
				$output .= ")";
			} elsif (@texthooks > 1) {
				$output .= " (EQUATIONS: ";
				$output .= join($newline_separator, @texthooks);
				$output .= ")";
			}
		}

		# links are stored in <arrowlink> child nodes, but only on the originating node
		# before starting the recursion, all arrowlink endpoints were stored in %linktargets
		# if the current node ID is in %linktargets, then something is pointing to here (hence we need to print the current node ID)
		if ($opts{'print_connectors'}) {
			if ( exists $linktargets{$nodeid} ) {
				$output .= " (ID: ";
				$output .= $nodeid;
				$output .= ")";
			}
			# if the current node has <arrowlink> subnodes, then this node is pointing to somewhere else (hence we need to print the destination IDs as "see also") 
			# I call this "connector", and the URLs embedded into a node "link"
			my @arrowlinks = $node->getChildrenByTagName("arrowlink");
			my @textarrowlinks;
			foreach my $arrowlink (@arrowlinks) {
				push @textarrowlinks, $arrowlink->getAttribute("DESTINATION");
			}
			if (@textarrowlinks == 1) {
				$output .= " (LINKED_ID: ";
				$output .= $textarrowlinks[0];
				$output .= ")";
			} elsif (@textarrowlinks > 1) {
				$output .= " (LINKED_IDS: ";
				$output .= join(", ", @textarrowlinks);
				$output .= ")";
			}
		}

		# don't print this node, if it is not in the sub-tree specified with -r|--root=s
		my $quiet = 0;
		if (defined $opts{'root'}) {
			if ( not "$parent/$text" =~ $opts{'root'} ) {
				$quiet = 1;
			}

		}

		# handle appointments (if --appointment|--ical) was specified
		# TODO
		# - extract date
		# - extract body, follow symlinks and include symlinks aswell
		# - generate ICAL output
		# write a script that takes ical as input, and adds/updates appointments accordingly in a google calendar (so that the output of this script can be piped into the calendar-uploader)
		if (defined $opts{'appointments'} and $opts{'appointments'}) {
			if ( "$text" =~ /^appointment: (?<details>.*)/i ) {
				
				# the part of $text which wasn't matched by the date regex. At the moment, everything after ""appointment:"
				my $remaining = "$+{details}";

				# parse date from the parent line (this is a fallback if the appointment only specifies times, but not dates)
				my $parentdate;
				if ( "$parent" =~ /(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})/ ) {
					$parentdate = "$+{year}-$+{month}-$+{day}";
				}
				
				# parse time
				my $starttime;
				my $endtime;
				# find "at (.*) - (.*)". The first match will be in $+{from}, the second in $+{to}.
				# At the same time, we need to keep everything before and after the match (excluding semicolon and white spaces).
				if ( "$remaining" =~ /(?<pre>.*)\s*at (?<from>[^;]*) - (?<to>[^;]*);?\s*(?<post>.*)/i ) {
					$starttime = $+{from};
					$endtime = $+{to};

					# could be /^(?<hour>\d{1,2}):(?<min>\d{2})$/, then we have to append a date
					my $timematch = '^(?<hour>\d{1,2}):(?<min>\d{2})$';
					# could be /^(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2}) (?<hour>\d{1,2}):(?<min>\d{2})$/
					my $datetimematch = '^(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2}) (?<hour>\d{1,2}):(?<min>\d{2})$';

					# starttime
					if ( "$starttime" =~ /$datetimematch/ ) {
						# TODO build a date
					} elsif ( "$starttime" =~ /$timematch/ ) {
						# TODO append parenddate (or abort if not specified), and build a date
					} else {
						warn "couldn't parse time $starttime\n";
					}

					# endtime
					if ( "$endtime" =~ /$datetimematch/ ) {
						# TODO build a date
					} elsif ( "$endtime" =~ /$timematch/ ) {
						# TODO append parenddate (or abort if not specified), and build a date
					} else {
						warn "couldn't parse time $endtime\n";
					}

				} else {
					$starttime = "00:00";
					$endtime = "23:59";
					# TODO append parenddate (or abort if not specified), and build a date
				}

				# the part of $text which wasn't matched by the date regex
				$remaining = "$+{pre}$+{post}";

				# parse location
				my $location;
				# find "in (.*)", again keep the pre and post of the regex without the semicolon and whitespaces
				if ( "$remaining" =~ /(?<pre>.*)\s*in (?<location>[^;]*);?\s*(?<post>.*)/i ) {
					$location = $+{location};
				} else {
					warn "couldn't extract location from $text\n";
				}

				# subject
				# the remaining part of the $text is the subject of the appointment
				$remaining = "$+{pre}$+{post}";
				my $subject = $remaining;

				# TODO extract body
				# body
				# the body consists of the subject, a newline and then the whole subtree of the node
				# TODO: this is a hack. Instead of changing the global $opts{'appointments'}, recurse should take \%opts as argument 
				# TODO: follow symlinks (maybe as an extra option in $opts? how to handle loops?)
				$opts{'appointments'} = 0;	
				my $body = "$subject\n\n" . recurse("$parent/$text", $node, 0);
				$opts{'appointments'} = 1;	# TODO this is a hack

				$output = "appointment:\n  start: $starttime\n  end: $endtime\n  location: $location\n  subject: $subject\n  body: $body";
			} else {
				# we are in --appointment|--ical mode, but this node doesn't contain an appointment
				$quiet = 1;
			}
		}


		# truncate if this node matches at least one of the truncation patterns
		my $truncate = 0;
		foreach my $pattern (@{ $opts{'truncate_pattern'} }) {
			if ( "$parent/$text" =~ /$pattern/i ) {
				$truncate = 1;
				last;
			}
		}
		if ( $truncate ) {
			$output .= " (";
			$output .= $node->getElementsByTagName("node")->size();
			$output .= " nodes truncated)";

			# output
			if (!$quiet) {
				# build up complete output
				$complete_output .= $output . "\r\n";
			}
		} else {

			# output
			if (!$quiet) {
				# build up complete output
				$complete_output .= $output . "\r\n";

				# recurse one level deeper
				$complete_output .= recurse("$parent/$text", $node, $level+1);
			} else {
				# recurse at same level, because we haven't reached the root of the subtree yet
				$complete_output .= recurse("$parent/$text", $node, $level);
			}

		}
	}
	return $complete_output;
}

__END__

=head1 NAME

B<mmtotxt_xml.pl> - MindMap to TXT converter

=head1 DESCRIPTION

B<mmtotxt_xml.pl> consumes a FreeMind or FreePlane *.mm 
document and exports it into a plaintext file. The plaintext file
is indented so that it can easily be folded with plaintext editors such
as VIM.

=head1 SYNOPSIS

B<mmtotxt_xml.pl>
S<[B<-h|-H|--help|--usage>]>
S<[B<--man>]>
S<[B<-f|--file|--infile|--input> I<INFILE>]>
S<[B<-o|--outfile|--output> I<OUTFILE>]>
S<[B<--appointments|--ical>]>
S<[B<-i|--indent> I<INDENT>]>
S<[B<-N|--newline>]>
S<[B<-ns|--separator> I<NEWLINE_SEPARATOR>]>
S<[B<-L|--links>]>
S<[B<-I|--icons>]>
S<[B<-A|--attributes>]>
S<[B<-F|--formula>]>
S<[B<-C|--connectors>]>
S<[B<-t|--truncate> I<TRUNCATE_PATTERN> [I<TRUNCATE_PATTERN>]]>
S<[B<-r|--root> I<ROOT>]>
S<[B<-a|--age> I<MIN_AGE>]>
S<[B<-j|--join-newlines>]>
S<[B<-w|--whole-path>]>

=head1 EXAMPLES

=over 8

=item B<-h|-H|--help|--usage>

print the help menu

=item B<--man>

print the man page

=item B<-f|--file|--infile|--input> I<INPUT FILE>

specify the F<*.mm> file to use as input
if omitted, the input is read from STDIN

=item B<-o|--outfile|--output> I<OUTPUT_FILE>

specify the F<*.txt> file to use as output
if omitted, the output is printed to STDOUT

=item B<--appointments|--ical>

Instead of outputting the mind map as a text representation, appointments
are exportet. An appointment is any node in one of the following special format: 

C<appointment: at 16:30 - 19:00; in Zurich; watch StarWars with friends>

C<appointment: in Zurich; watch StarWars with friends>

In the first case, an appointment from 16:30 until 19:00 is created, with location I<Zurich> 
and subject I<watch StarWars with friends>. The second node would create an all-day event.

All subnodes of such an appointment-node will be added as description/body to the appointment. If 
the appointment-node is simply a link to another node (probably where all relevant stuff for the meeting is),
then the target of the link (with all subnodes) is included in the appointment's body.

=item B<-i|--indent> I<NUMBERS>

the number of spaces to use as indent per level
if omitted, the default of 4 spaces is used

=item B<-N|--newline>

if a node contains newlines, then replace them with proper
newlines and indents, so that those lines don't stand out
from the tree

=item B<-ns|--separator> I<SEPARATOR>

the separator to be used when newlines are replaced with proper
newlines
the default value is ' \- ', i.e if a node contains newlines in
the MindMap then it will be printed as:

    This is Node X with 3 lines
     \- on the 2nd line, there is some text
     \- and on the 3rd line, some more

=item B<-L|--links>

whether external links (URLs) should be printed. Please note, 
that if a node's text and external link are the same, then the
link is never printed

=item B<-I|--icons>

whether the icon names should be printed

=item B<-A|--attributes>

whether the attributes should be printed. Multiple attributes
will be separated by the separator specified with the 
-ns|--separator option

=item B<-F|--formula>

whether the formula (LaTeX) should be printed. As the LaTeX 
can't be formatted, it is printed out in its raw form

=item B<-C|--connectors>

whether the internal connectors should be printed. Because it
is not possible to represent the graphical arcs in a plaintext
file, both ends of the connector will have their node ID 
printed. This makes it possible to search for the endpoint of
the connector.

Example: two nodes "Source" and "Target", and a connector pointing from "Source" --> "Target" would be displayed like this:

	Source (LINKED_IDS: ID_5143)
	Target (ID: ID_5143)

=item B<-t|--truncate> I<PATTERN> [I<PATTERN>]

a node matching any of the given patterns will be truncated,
i.e. its child nodes will not be printed. The pattern is
matched against the hierarchical name of the node, which
consists of all its parent node's names (separated with a "/")
and its own name.

Example: consider the following hierarchy:

	top
		node 1
		node 2
			subnode x
			subnode y	<-- (*)

then the node marked with (*) would have a hierarchical name
S</top/node 2/subnode y>

=item B<-r|--root> I<ROOT>

Defines the path to the root node, where to start the output. In the above example (see the B<-t|--truncate> option),
specifying S<--root /top/node2/> will only print out node 2, and subnodes x and y (but omit top and node 1).

=item B<-a|--age> I<MIN_AGE>

If specified, then the output file is only generated if it is older than AGE seconds.

=item B<-j|--join-newlines>

Instead of properly indenting nodes with multiple lines, the node's lines are all joined together by the newline-separator characters. For example,
if you have a node with three lines "line1", "line2" and "line3", then normally those lines would be printed separated by newlines, but correctly
indented. If you specify the B<-j|--join-newlines> option however, the node is printed as "line1line2line3". If you want to specify a separator
in between the individual lines, specify the newline separator with the B<-ns|--separator> option. For example, the two options
B<--separator ', '> and B<--join-newlines> leads to "line1, line2, line3" in the output.

=item B<-w|--whole-path>

Prints the whole path (i.e. all parents nodes) in front of this node's name. Thus, in above example, subnode y would be printed as C<top/node 2/subnode y>.



=back


=cut

