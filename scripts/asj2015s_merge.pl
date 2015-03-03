#!/usr/bin/perl

use strict;
use utf8;

use Data::Dumper;
use JSON;

my $src_sessions = shift || "asj2015s_sessions.json";
my $src_data     = shift || "asj2015s_data.json";

my $json_sessions = JSON->new->decode( join("", loadtext($src_sessions)) );
my $json_data     = JSON->new->decode( join("", loadtext($src_data)) );

# Make data table
my %session_data = ();
foreach my $d (@{$json_data}) {
	$session_data{$d->{id}} = $d;
}

# Merge
foreach my $sess_day (@{$json_sessions}) {
	foreach my $sess_room (@{$sess_day}) {
		foreach my $sess_sess (@{$sess_room->{sessions}}) {
			foreach my $sess_data (@{$sess_sess->{data}}) {
				#print Dumper($sess_data);
				#print Dumper($session_data{"1-P-1"});
				$sess_data = $session_data{$sess_data->{id}};
				#print Dumper($sess_data);
				#last;
			}
			#last;
		}
		#last;
	}
	#last;
}

print JSON->new->utf8->encode($json_sessions);

exit 0;

sub loadtext {
	my $filename = shift;
	my $fp;
	my @lines;
	
	open $fp, "<:utf8", $filename || die "Error: OpenR: $filename";
	@lines = <$fp>;
	close($fp);
	
	return @lines;
}
