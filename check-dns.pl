#!/usr/bin/perl

use strict;
use warnings;

=pod

=head1 NAME

B<check-dns.pl> - checking DNS servers for consistency

=head1 DESCRIPTION

B<check-dns.pl> checks the responses from multiple DNS servers for consistency.

=head1 SYNOPSIS

B<check-dns.pl> [--help|--man] 
-n|--name|--names I<NAME> [I<NAME>...]
[-a|--all-names]
[--axfr-ns I<AXFR_NAMESERVER>]
[--additional-ns I<ADDITIONAL_NAMESERVER> [I<ADDITIONAL_NAMESERVER>...]]
[--no-check-default-ns]
[-t|--type I<TYPE> [I<TYPE>...]]

=head1 OPTIONS

=over 8

=item B<--help>

Print a brief help message and exit.

=item B<--man>

Print the manual page and exit.

=item B<-n | --name | --names> I<NAME> [I<NAME>...]

One or multiple resource record names to query. All specified names must be served from the same nameservers.

=item B<-a | --all-names>

If a AXFR server is given (with the B<--axfr-ns> parameter), then all resource records can be fetched and checked for consistency. In this case, 
the B<-n|--name> parameter is the domain to query for an AXFR.

=item B<--axfr-ns> I<AXFR_NAMESERVER>

The nameserver from where to obtain an AXFR dump.  The AXFR_NAMESERVER has to allow AXFR requests.

=item B<--additional-ns> I<ADDITIONAL_NAMESERVER> [I<ADDITIONAL_NAMESERVER>...]

Additional nameservers which will be queried for the resource record name. All default nameservers (as in the NS records of this zone) and those additional nameservers are compared to each other.

=item B<--no-check-default-ns>

By default, B<check-dns.pl> compares the resource records across all nameservers which are obtained from the NS type records. If you only want to check the nameservers given with B<--additional-ns> but not the default nameservers, you can specify the B<--no-check-default-ns>.

=item B<-t|--type> I<TYPE> [I<TYPE>...]

If you only want to query some types, you can specify them using the B<-t|--type> parameter. By default, ANY type is queried.

=back

=head1 EXAMPLE

My main purpose for this script is to compare DNS records after a migration of the DNS provider. I migrated everything from ZoneEdit (ns2.zoneedit.com was one of my nameservers) over to DNSMadeEasy (where axfr1.dnsmadeeasy.com provides AXFR info). B<check-dns.pl> now compares the records for my domain I<benediktkoeppel.ch> between ZoneEdit and DNSMadeEasy:

	check-dns.pl -n benediktkoeppel.ch --axfr-ns axfr1.dnsmadeeasy.com --all-names --additional-ns ns2.zoneedit.com

The script will highlight any discrepancies between the current nameservers (the NS records from axfr1.dnsmadeeasy.com) and the additional nameserver ns2.zoneedit.com:

	Query for benediktkoeppel.ch (MX) returned mismatching information:
		ns0.dnsmadeeasy.com, ns1.dnsmadeeasy.com, ns3.dnsmadeeasy.com, ns4.dnsmadeeasy.com, ns2.dnsmadeeasy.com, axfr1.dnsmadeeasy.com returned:
			benediktkoeppel.ch.     300     IN      MX      0 aspmx.l.google.com. \
			benediktkoeppel.ch.     300     IN      MX      10 alt1.aspmx.l.google.com. \
			benediktkoeppel.ch.     300     IN      MX      10 alt2.aspmx.l.google.com. \
			benediktkoeppel.ch.     300     IN      MX      20 aspmx2.googlemail.com. \
			benediktkoeppel.ch.     300     IN      MX      20 aspmx3.googlemail.com.
		ns2.zoneedit.com returned:
			benediktkoeppel.ch.     300     IN      MX      0 ASPMX.L.GOOGLE.COM. \
			benediktkoeppel.ch.     300     IN      MX      10 ALT1.ASPMX.L.GOOGLE.COM. \
			benediktkoeppel.ch.     300     IN      MX      10 ALT2.ASPMX.L.GOOGLE.COM. \
			benediktkoeppel.ch.     300     IN      MX      20 ASPMX2.GOOGLEMAIL.COM. \
			benediktkoeppel.ch.     300     IN      MX      20 ASPMX3.GOOGLEMAIL.COM.
	Query for benediktkoeppel.ch (NS) returned mismatching information:
		ns2.zoneedit.com returned:
			benediktkoeppel.ch.     7200    IN      NS      ns2.zoneedit.com. \
			benediktkoeppel.ch.     7200    IN      NS      ns8.zoneedit.com.
		ns0.dnsmadeeasy.com, ns1.dnsmadeeasy.com, ns3.dnsmadeeasy.com, ns4.dnsmadeeasy.com, ns2.dnsmadeeasy.com, axfr1.dnsmadeeasy.com returned:
			benediktkoeppel.ch.     86400   IN      NS      ns0.dnsmadeeasy.com. \
			benediktkoeppel.ch.     86400   IN      NS      ns1.dnsmadeeasy.com. \
			benediktkoeppel.ch.     86400   IN      NS      ns2.dnsmadeeasy.com. \
			benediktkoeppel.ch.     86400   IN      NS      ns3.dnsmadeeasy.com. \
			benediktkoeppel.ch.     86400   IN      NS      ns4.dnsmadeeasy.com.
	Query for benediktkoeppel.ch (SOA) returned mismatching information:
		ns0.dnsmadeeasy.com, ns1.dnsmadeeasy.com, ns3.dnsmadeeasy.com, ns4.dnsmadeeasy.com, ns2.dnsmadeeasy.com, axfr1.dnsmadeeasy.com returned:
			benediktkoeppel.ch.     21600   IN      SOA     ns0.dnsmadeeasy.com. dns.dnsmadeeasy.com. ( \
								2012112703      ; Serial \
								14400   ; Refresh \
								300     ; Retry \
								86400   ; Expire \
								300 )   ; Minimum TTL
		ns2.zoneedit.com returned:
			benediktkoeppel.ch.     7200    IN      SOA     ns2.zoneedit.com. soacontact.zoneedit.com. ( \
								2012477237      ; Serial \
								60      ; Refresh \
								60      ; Retry \
								60      ; Expire \
								60 )    ; Minimum TTL

If your nameservers don't allow you to query AXFR requests, you can still use the script and specify each individual name of the resource records which you want to query. For example, if I want to check records for benediktkoeppel.ch and www.benediktkoeppel.ch (A records), I would run:

	check-dns.pl --names benediktkoeppel.ch www.benediktkoeppel.ch --additional-ns ns2.zoneedit.com -t A

=head1 PROBLEMS

If the zone has a sub-zone with its own nameserver, then the AXFR will have a record in its answer section pointing to this sub-zone namserver:
	
	subzone.benediktkoeppel.ch	300	IN	NS	subns.benediktkoeppel.ch

As a result, B<check-dns.pl> will query this subzone.benediktkoeppel.ch record from all nameservers. The nameservers will not respond
for the subzone in the anser section, but simply point to the subzone in their authority section. However, B<check-dns.pl> currently (incorrectly)
expects this response to be in the answer section and will print errors for this record.

=head1 AUTHOR

Benedikt Koeppel, L<mailto:code@benediktkoeppel.ch>, L<http://benediktkoeppel.ch>

=cut

use Getopt::Long qw(HelpMessage :config no_ignore_case);
use Pod::Usage;
use Net::DNS;
use List::MoreUtils qw(uniq);

# variables for command line options
my @names;		# the names of the RR to query (provided on the command line)
my $all_names = 0;	# query all RR (only possible if an AXFR server is specified)
my $axfr_ns;		# a nameserver returning an AXFR (required for the --all-names option)
my %names;		# all RR names, extracted from the AXFR (if the --all-names option is specified). This is a hash, so that each name/type pair occurs only once. $names{ RR name }{ RR type }.
my @ns;			# all the nameservers to query
my $no_check_default_ns = 0;	# disable checking the default nameservers (as given in the IN NS records)
my $debug = 0;		# print debugging information
my @types;		# types to query

# parse command line options
GetOptions(
	'H|?|help|usage'	=> sub { HelpMessage(-verbose => 1) },
	'm|man'			=> sub { HelpMessage(-verbose => 2) },
	'n|name|names=s@'	=> \@names,
	'a|all-names'		=> \$all_names,
	'axfr-ns=s'		=> \$axfr_ns,
	'additional-ns=s@'	=> \@ns,
	'no-check-default-ns'	=> \$no_check_default_ns,
	'd|debug'		=> \$debug,
	't|types|type=s@'	=> \@types
) or pod2usage( -verbose => 1, -msg => 'Invalid option', -exitval => 1);

# check for mandatory command line options
if ( !@names) {
	pod2usage(-verbose => 1,
		  -msg => '-n|--name|--names parameter is mandatory',
		  -exitval => 1);
}
if ( !defined $axfr_ns && $all_names == 1 ) {
	pod2usage(-verbose => 1,
		  -msg => 'You must specify a nameserver which delivers an AXFR if you want to use the -a|--all-names option',
		  -exitval => 1);
}
if ( !@ns && $no_check_default_ns ) {
	pod2usage(-verbose => 1,
		  -msg => 'You must specify some nameservers with the --additional-ns parameter if you don\'t want to query the default nameservers (--no-check-default-ns)',
		  -exitval => 1);
}

# convert the types to a Hash (for easier lookup)
# default search is for ANY records
my %types;
if ( !@types ) {
	print "DEBUG: Querying for ANY records by default\n" if $debug;
	$types{'ANY'} = 1;
} else {
	%types = map { $_ => 1 } @types;
}

# set up the DNS resolver
my $res = Net::DNS::Resolver->new;

# find the default nameservers, unless the --no-check-default-ns option was passed
unless ($no_check_default_ns) {
	foreach my $name (@names) {
		my $query = $res->query($name, "NS");
		if ($query) {
			foreach my $rr (grep { $_->type eq 'NS' } $query->answer) {
				print "DEBUG: Adding ".$rr->nsdname." to the list of nameservers\n" if $debug;
				push @ns, $rr->nsdname;
			}
		} else {
			warn "query failed: ", $res->errorstring, "\n";
		}
	}
}

# add the AXFR server to the list of nameservers
if ( defined $axfr_ns ) {
	print "DEBUG: Adding ".$axfr_ns." to the list of nameservers\n" if $debug;
	push @ns, $axfr_ns;
}

# abort if there are no name servers
@ns = uniq(@ns);
if ( !@ns ) {
	die "There are no valid nameservers to query.";
}

# build the list of RR names to query. If --all-names and an AXFR server are provided, get all RRs from the AXFR. Otherwise use $name
if ( defined $axfr_ns && $all_names == 1 ) {

	# get the names from the AXFR
	$res->nameservers($axfr_ns);
	foreach my $name (@names) {
		my @axfr = $res->axfr($name);
		foreach my $rr (@axfr) {
			next unless ( exists $types{'ANY'} || exists $types{$rr->type} ); # skip this RR if it is of no interesting type
			print "DEBUG: Adding ".$rr->name." (".$rr->type.") to the list of RR name/types\n" if $debug;
			$names{$rr->name}{$rr->type} = 1;
		}
	}
} else {
	# add all $name/$type pairs to the $names hash
	foreach my $name (@names) {
		# query $name for the default types in %types
		foreach my $t (keys %types) {
			print "DEBUG: Adding $name ($t) to the list of RR name/types\n" if $debug;
			$names{$name}{$t} = 1;
		}
	}
}

# abort if there are no resource record names
if ( !%names ) {
	die "There are no valid resource record names to query.";
}

# now query all name servers for all RR name/type combinations, and compare the results
foreach my $n (keys %names) {
	foreach my $t (keys %{$names{$n}}) {

		# will store the responses from each nameserver. Keyed by the response string, holding an array of nameservers that gave this response.
		my %responses;

		# query all nameservers
		foreach my $ns (@ns) {

			print "DEBUG: Querying $ns for $n ($t)\n" if $debug;

			# set the resolver to this nameserver ($ns)
			$res->nameservers($ns);

			# query resource records with $name and store all matching types. If a query returns more than one line of matching records, then they are sorted and stored with newlines in the %responses hash.
			my $response = $res->query($n, $t);
			my @response_arr;
			if (!defined $response) {
				print "ERROR: $ns did not return a response for $n ($t)\n";
				next;
			}
			foreach my $rr ($response->answer) {
				next unless $rr->type eq $t && $t ne "ANY";
				push @response_arr, $rr->string;
			}
			@response_arr = sort(@response_arr);
			my $response_str = join("\n", @response_arr);
			push @{$responses{$response_str}}, $ns;

		}

		# print all distinct responses and the servers where we got this info from
		if ($debug) {
			foreach my $rr (keys %responses) {
				print "DEBUG: Response from ".join(", ", @{$responses{$rr}}).":\n";
				print "DEBUG: ".$rr."\n";
			}
		}

		# compare results
		# if the %responses hash has only one key, all nameservers have returned the same information
		# otherwise, some nameservers have responded with mismatching information
		if ( keys %responses != 1 ) {
			print "Query for $n ($t) returned mismatching information:\n";
			foreach my $rr (keys %responses) {

				# print the servers
				print "\t".join(", ", @{$responses{$rr}})." returned:\n";
				
				# then print the response
				print "\t\t".join(" \\\n\t\t", split(/\n/, $rr))."\n";
			}
		}
	}
}
