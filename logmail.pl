#!/usr/bin/perl

use v5.18;
use strict;
use warnings;

=pod

=for comment This is a POD documentation. The syntax is described here:
http://perldoc.perl.org/perlpod.html. Please note that the blank lines are
required.

=head1 NAME

B<logmail.pl> - collect logging output and send it via email

=head1 DESCRIPTION

B<logmail.pl> reads log lines from STDIN and sends it via email to a recipient.
It can be configured to send mail regularly after a fixed period of time. This
is useful for long-running processes.

=head1 SYNOPSIS

B<logmail.pl> [--help|--man] [-s|--subject I<SUBJECT>] [-t|--time I<SECONDS>] I<TO_ADDR>

=head1 OPTIONS

=over 8

=item Document all command line options, each with a separate C<=item>.

=item B<--help>

Print a brief help message and exit.

=item B<--man>

Print the manual page and exit.

=item B<-s | --subject> I<SUBJECT>

Subject of the emails to be sent.

=item B<-t | --time> I<TIME>

The time interval after which an email should be sent, if the incoming process
is not yet finished. If not specified, only one email will be sent when EOF is
reached.

=item I<TO_ADDR>

Recipient of the email.

=back

=head1 AUTHOR

Benedikt Koeppel, L<mailto:code@benediktkoeppel.ch>, L<http://benediktkoeppel.ch>

=cut

use Getopt::Long qw(HelpMessage :config no_ignore_case);
use Pod::Usage;
use Email::MIME;
use Email::Sender::Simple qw(sendmail);
use Sys::Hostname;
use threads;
use threads::shared;

# variables for command line options
my $subject = "LogMail Message";
my $seconds;
my $recipient;

# list of all unprocessed messages
my @messages :shared;

# parse command line options
GetOptions(
	'H|?|help|usage'	=> sub { HelpMessage(-verbose => 1) }, # display brief help
	'm|man'			=> sub { HelpMessage(-verbose => 2) }, # display complete help as man page
	's|subject=s'		=> \$subject,
	't|time=s'		=> \$seconds
) or pod2usage( -verbose => 1, -msg => 'Invalid option', -exitval => 1);

$recipient = shift @ARGV;

# check for mandatory command line options
if ( !defined $recipient ) {
	pod2usage(-verbose => 1,
		  -msg => '-o|--optionstring parameter is mandatory',
		  -exitval => 1);
}

# the fun begins here (i.e. your code :-) )

## send email out
sub send_email {

	# if @messages is empty, don't send an email
	if (!@messages) {
		return;
	}

	# build up message body
	my $body = join("\n", @messages);
	@messages = ();

	#print "Sending email to $recipient with subject \"$subject\"\n";
	#print $body . "\n";

	# sender
	my $username = getlogin || getpwuid($<) || "unknown";
	my $hostname = hostname;
	my $sender = "${username}\@${hostname}";

	# send email
	my $message = Email::MIME->create(
		header_str => [
			From => $sender,
			To => $recipient,
			Subject => $subject,
		],
		attributes => {
			encoding => 'quoted-printable',
			charset => 'ISO-8859-1',
		},
		body_str => $body
	);
	sendmail($message);
	
}

## Ctrl-C should send email nevertheless
#$SIG{'INT'} = sub {
#	send_email();
#};

## background check to send emails
sub timer {
	for (;;) {
		my $start = time;
		
		send_email();

		if ((my $remaining = $seconds - (time - $start)) > 0) {
			sleep $remaining;
		}
	}
}



## main
# start background timer
my $thread;
if ( defined $seconds ) {
	$thread = threads->new(\&timer);
}

# read from STDIN into @messages
while(<>) {
	chomp;
	push(@messages, $_);
	print $_."\n";
}

# at the end, send email out
#if ( defined $thread ) {
#	$thread->join();
#}
send_email();

