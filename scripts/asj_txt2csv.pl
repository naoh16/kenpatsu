#!/usr/bin/perl

use strict;

use utf8;
use Lingua::JA::Kana;
use Data::Dumper;

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

my $debug = 0;

my @data = ();

$data[0] = []; # 1st day
$data[1] = []; # 2nd day
$data[2] = []; # 3rd day

# Load and restruct the text
my @lines = ();
while(my $line = <>) {
	$line =~ s/[\r\n]+//g;

	if($line =~ /^\d+\-[0-9PQRS]+\-\d+/) {
		while($line !~ /…/) {
			my $newline = <>;
			$newline =~ s/[\r\n]+//g;
			$line .= $newline;
		}
		#$line =~ s/　+/　/g;
	}
	
	push @lines, $line;
}

if($debug > 2) {
	my $fp;
	open $fp, ">:utf8", "debug.txt" || die "Error";
	foreach(@lines) {
		print $fp $_ . "\n";
	}
	close($fp);
}

# Parser
my $cur_session = undef;
my $cur_place   = undef;
my $cur_day = -1;
my ($st_h, $st_m, $en_h, $en_m);
my $session_order = 0;

my $poster_session = "";

my %place_refs = ();
my %place_poster_refs = ();

my %poster = (
	main_z => "",
	sub_z  => "",
	st_h => "",
	st_m => "",
	et_h => "",
	et_m => ""
);

foreach my $line ( @lines ) {
	if($line =~ /^　ポスタ会場　　(.*)$/) {
		$poster_session = $1;
		next;
	}

	if($poster_session ne "") {
		#print ">" . $line . "\n";
		
		if($line =~ /^午[前後].* \(?(\d+):(\d+)～(\d+):(\d+)\)　　座長 (.*)　　副座長 (.*)$/) {
			#print "■ start = |$1:$2|, end = |$3:$4|\n";
			#print "■ 座長 = |$5|, 副座長 = |$6|\n";
			$poster{st_h} = $1;
			$poster{st_m} = $2;
			$poster{et_h} = $3;
			$poster{et_m} = $4;
			$poster{main_z} = $5;
			$poster{sub_z}  = $6;
			next;
		}
#		elsif($line =~ /ポスター室(.*)\t(\d+\-[PQR]\-\d+)～(\d+\-[PQR]\-\d+)\t/) {
#			my $room = $1;
#			$room =~ tr/①②③④/1234/;
#			next;
#		}
		elsif($line =~ /^ポスター室(.)/) {
			my $room = $1;
			$room =~ tr/①②③④/1234/;
			#print "■ PosterHeader: day = |$cur_day|, room = |$room|\n";
			
			my $place_id = $cur_day . "P" . $room;

			if(exists $place_refs{$place_id}) {
				$cur_place = $place_refs{$place_id};
			} else {
				my $place_num = 10 + $room - 1;
				print STDERR "Place no.: " . $place_num . "\n";
				$data[$cur_day]->[$place_num] = {
					place    => "ポスター室" . $room,
					sessions => []
				};
				$cur_place = $data[$cur_day]->[$place_num];
				$place_refs{$place_id} = $cur_place;
			}

			push @{$cur_place->{sessions}}, {
				theme => $poster_session,
				zacho => $poster{main_z}, sub_z => $poster{sub_z},
				start => sprintf("%02d:%02d", $poster{st_h}, $poster{st_m}),
				end   => sprintf("%02d:%02d", $poster{et_h}, $poster{et_m}),
				data  => []
			};
			$cur_session = $cur_place->{sessions}[$#{$cur_place->{sessions}}];
			$session_order = 0;
		}

		# PARSE POSTER PRESENTATION
		if($line =~ m/(?:(\d+-[PQRS]-\d+) (.*?)　+(.*?)(\(\d+\)))/) {
			my $pid = $1;
			my $title = $2;
			my $authors = $3;
			my $page = $4;
			my $st_h = $poster{st_h};
			my $st_m = $poster{st_m};
			$title =~ s/^ //g;
			$title =~ s/^　//g;
			$authors =~ s/ //g;
			$authors =~ s/　//g;
			$authors =~ s/…//g;

			my $session_length = 120;
			
			#print join("\t", $pid, $title, $authors, $page) . "\n";
			#print '    {"id": "' . $pid . '", "title": "' . $title . '", "authors": "' . $authors . '", "page": "' . $page . '"},'."\n";
			push @{$cur_session->{data}}, {
				id => $pid, title => $title,
				authors => $authors, page => $page,
				start => session_time(\$st_h, \$st_m),
				end   => session_time(\$st_h, \$st_m, $session_length)
			};
			
			++$session_order;
		}

		elsif($line =~ /第([１２３])日　/) {
			$poster_session = "";
			next ;
		}
		next;
	}
	
	if($line =~ /\t第([１２３])日/) {
		#print $1, $line, "\n";
		$cur_day = 0 if($1 eq "１");
		$cur_day = 1 if($1 eq "２");
		$cur_day = 2 if($1 eq "３");
		for(my $j=0; $j<10; ++$j) {
			$data[$cur_day]->[$j] = {};
		}
	}
	next if($cur_day < 0);

	# PARSE PLACE
	if($line =~ /^(?:　| )(第([０-９]+)会場)/) {
		if(exists $place_refs{$cur_day . $1}) {
			$cur_place = $place_refs{$cur_day . $1};
		} else {
#			push @{$data[$cur_day]}, {
##				place    => $line,
#				place    => $1,
#				sessions => []
#			};
#			$cur_place = $data[$cur_day][$#{$data[$cur_day]}];
			my $place_num = utf8_zen2han($2) - 1;
			print STDERR "Place no.: " . $place_num . "\n";
			$data[$cur_day]->[$place_num] = {
				place    => $1,
				sessions => []
			};
			$cur_place = $data[$cur_day]->[$place_num];
			$place_refs{$cur_day . $1} = $cur_place;
		}
		next;
	}

#	# PARSE ZACHOU
	if($line =~ /午[前後].*[前後]半\((\d+):(\d+)～(\d+):(\d+)\)/) {
		my ($title, $zacho) = split(/座長/, $line, 2);
		my ($main_z, $sub_z) = split(/副座長/, $zacho, 2);
		($st_h, $st_m, $en_h, $en_m) = ($1,$2,$3,$4);
		$title =~ s/　//g;
		$main_z =~ s/(^\s+|\s+$)//g;
		$main_z =~ s/\s+/ /g;
		$sub_z =~ s/(^\s+|\s+$)//g;
		$sub_z =~ s/\s+/ /g;
		
		$title =~ /［([^］]+)］/;
		my $theme = $1;
		
#		push @{$data[$cur_day]}, {theme => $title, zacho => $main_z, sub_z => $sub_z,
		push @{$cur_place->{sessions}}, {theme => $theme, zacho => $main_z, sub_z => $sub_z,
			start => sprintf("%02d:%02d", $st_h, $st_m), end => sprintf("%02d:%02d", $en_h, $en_m),
			data  => []
		};
#		$cur_session = $data[$cur_day][$#{$data[$cur_day]}];
		$cur_session = $cur_place->{sessions}[$#{$cur_place->{sessions}}];
		$session_order = 0;
	}
	
	# PARSE PRESENTATION
	if($line =~ m/(?:(\d+-\d+-\d+) (.*?)　+(.*?)(\(\d+\)))/) {
		my $pid = $1;
		my $title = $2;
		my $authors = $3;
		my $page = $4;
		
		$title =~ s/^ //g;
		$title =~ s/^　//g;
		$authors =~ s/ //g;
		$authors =~ s/　//g;
		$authors =~ s/…//g;

		my $session_length = 15;
		
		if($title =~ /招待講演/ && $title =~ /（(\d+)分）/) {
			$session_length = $1;
			#print $session_length . "!!!\n";
		}
		
		#print join("\t", $pid, $title, $authors, $page) . "\n";
		#print '    {"id": "' . $pid . '", "title": "' . $title . '", "authors": "' . $authors . '", "page": "' . $page . '"},'."\n";
#		push @{$data[$cur_day]}, {
		push @{$cur_session->{data}}, {
			id => $pid, title => $title,
			authors => $authors, page => $page,
			start => session_time(\$st_h, \$st_m),
			end   => session_time(\$st_h, \$st_m, $session_length)
		};
		
		++$session_order;
	}
}

print_array(\@data);
exit;

sub print_array {
	my $d = shift;
	
	my $cnt = 0;
	print "[";
	foreach my $val (@{$d}) {
		print "," if($cnt++ > 0);
		
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

	foreach my $k (keys %{$d}) {
		next if( $k eq "id" || $k eq "start" || $k eq "end");
		next if( ref($d->{$k}) eq "ARRAY");
		
		print "," if($cnt++ > 0);
		print qq|"$k":"$d->{$k}"|;
	}

	foreach my $k (keys %{$d}) {
		next if( $k eq "id" || $k eq "start" || $k eq "end");
		next unless( ref($d->{$k}) eq "ARRAY");

		print "," if($cnt++ > 0);
		print qq|"$k":|;
		print_array($d->{$k});
	}

	print "}";
}

sub session_time {
	my $st_h = shift;
	my $st_m = shift;
	my $session_length = shift;
	
	my $tmp_m = 0 + $$st_m + $session_length;
	
		my $ret_str = sprintf("%02d:%02d", $$st_h + int($tmp_m / 60), $tmp_m % 60);

	if($session_length > 0) {
		$$st_h = $$st_h + int($tmp_m / 60);
		$$st_m = $tmp_m % 60;
	}
	
	return $ret_str;
}

#
# http://adiary.blog.abk.nu/0263
#
sub utf8_zen2han {
	my $str = shift;
	my $flag = utf8::is_utf8($str);
	Encode::_utf8_on($str);

	$str =~ tr/　！”＃＄％＆’（）＊＋，－．／０-９：；＜＝＞？＠Ａ-Ｚ［￥］＾＿｀ａ-ｚ｛｜｝/ -}/;

	if (!$flag) { Encode::_utf8_off($str); }
	return $str;
}
