#!/usr/bin/perl
# データファイルはExcelでCSVを読み込んでからテキストファイル（タブ区切りtxt; 拡張子tsv）に変換しておく

use strict;

use utf8;
use Lingua::JA::Kana;
use Data::Dumper;

binmode STDIN, ":encoding(cp932)";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

my $debug = 0;

my $src_filename = shift || "2015spring_program.tsv";

my @data = ();

my $fp = undef;
open $fp, "<:encoding(cp932)", $src_filename || die "Error: OpenR: $src_filename";

# Load and restruct the text
my @lines = ();
<$fp>; # Read 1st line as header.
while(my $line = <$fp>) {
	$line =~ s/[\r\n]+//g;
	my($time, $pid, $title, $authors, $page) = split(/\t/, $line);
	$pid =~ s/"//g;
	$title =~ s/"//g;
	$authors =~ s/"//g;
	
	next unless($pid =~ /\d\-[0-9PQRS]{1,2}\-\d{1,2}/o);

	next unless($time =~ /(\d+):(\d+)[^\d]+(\d+):(\d+)/o);
	my($st_h, $st_m, $en_h, $en_m) = ($1,$2,$3,$4);
	
	push @data, {
		id => $pid, title => $title,
		authors => $authors, page => $page,
		start => sprintf("%02d:%02d", $st_h, $st_m),
		end   => sprintf("%02d:%02d", $en_h, $en_m),
	};
}

close($fp);

print_array(\@data);

exit 0;

sub print_array {
	my $d = shift;
	
	my $cnt = 0;
	print "[";
	foreach my $val (@{$d}) {
		print ",\n" if($cnt++ > 0);
		
		if( ref($val) eq "HASH" ) {
			print_hash($val);
		} elsif( ref($val) eq "ARRAY" ) {
			print_array($val);
		} else {
			print qq|"$val"|;
		}
	}
	print "]";
}

sub print_hash {
	my $d = shift;
	
	my $cnt = 0;
	#print Dumper $d;
	
	print "{";

	if(exists $d->{id}) {
		print qq|"id":"$d->{id}"|;
		++$cnt;
	}
	if(exists $d->{start}) {
		print "," if($cnt++ > 0);
		print qq|"start":"$d->{start}"|;
		++$cnt;
	}
	if(exists $d->{end}) {
		print "," if($cnt++ > 0);
		print qq|"end":"$d->{end}"|;
		++$cnt;
	}

	foreach my $k (sort keys %{$d}) {
		next if( $k eq "id" || $k eq "start" || $k eq "end");
		next if( ref($d->{$k}) eq "ARRAY");
		
		print "," if($cnt++ > 0);
		print qq|"$k":"$d->{$k}"|;
	}

	foreach my $k (sort keys %{$d}) {
		next if( $k eq "id" || $k eq "start" || $k eq "end");
		next unless( ref($d->{$k}) eq "ARRAY");

		print "," if($cnt++ > 0);
		print qq|"$k":|;
		print_array($d->{$k});
	}

	print "}";
}
