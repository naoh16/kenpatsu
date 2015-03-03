#!/usr/bin/perl
#
# 時間の:に全角：が混じっている場合は、データファイルを手動で修正する
#
use strict;

use utf8;
use Lingua::JA::Kana;
use Data::Dumper;

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

my $g_debug = 3;

my $src_filename = shift || "2015spring_program.txt";

my @data = ();
$data[0] = []; # 1st day
$data[1] = []; # 2nd day
$data[2] = []; # 3rd day

my @lines = load_txtfile($src_filename);
#output_session_data_raw(\@lines); # for debug

parse_session_data(\@lines, \@data);
print_array(\@data);

exit 0;

#
# Functions
#
sub load_txtfile {
	my $filename = shift;
	my @lines = ();
	my $fp = undef;
	
	open $fp, "<:utf8", $filename || die "Error: Open: $filename\n";
	while(my $line = <$fp>) {
		$line =~ s/[\r\n]+//g;

		if($line =~ /^\d+\-[0-9PQRS]+\-\d+ /) {
			while($line !~ /…/) {
				my $newline = <$fp>;
				$newline =~ s/[\r\n]+//g;
				$line .= $newline;
			}
			#$line =~ s/　+/　/g;
		}
		
		push @lines, $line;
	}
	close($fp);

	if($g_debug > 2) {
		my $fp2;
		open $fp2, ">:utf8", "debug.txt" || die "Error";
		foreach(@lines) {
			print $fp2 $_ . "\n";
		}
		close($fp2);
	}
	
	return @lines;
}


sub parse_session_data {
	my $lines = shift;
	my $data  = shift;

	my $m_day  = -1;
	my $m_room = "";
	my $m_room_theme = "";
	my $ref_places = undef;
	my %session = (
		start => "", # 開始時刻
		end   => "", # 終了時刻
		zacho => "", # 座長
		sub_z => "", # 副座長
		theme => ""  # セッションテーマ
	);
	my %poster_session = ();
	
	my $state_in_poster = 0;
	my @ref_poster_rooms;
	my $ref_session_data;

	foreach my $line ( @{$lines} ) {
		# DAY
		if($line =~ /^第(.*)日　/) {
			$m_day = utf8_zen2han($1);
			# Prepare poster rooms...
			@ref_poster_rooms = (
				{place => "ポスター室1", sessions => []},
				{place => "ポスター室2", sessions => []}
			);
			push @{$data->[$m_day-1]}, $ref_poster_rooms[0];
			push @{$data->[$m_day-1]}, $ref_poster_rooms[1];
			
			$state_in_poster = 0;
			next;
		}
		# DAY > ROOM
		elsif($line =~ /^　(第.+会場)　　(.*)$/) {
			$m_room = $1;
			$m_room_theme = $2;

			if($m_room ne $ref_places->{place}) {
				$ref_places = {
					place    => $m_room,
					sessions => []
				};
				push @{$data->[$m_day-1]}, $ref_places;
			}
			
			$state_in_poster = 0;
			next;
		}
		elsif($line =~ /^　(ポスタ会場)　　(.*)$/) {
			$m_room_theme = $2;

			$state_in_poster = 1;
			next;
		}
		elsif($line =~ /^ポスター室(.)（/) {
			my $room = $1;
			$room =~ tr/①②③④/1234/;
			$m_room = "ポスター室".$room;
			$ref_places = $ref_poster_rooms[$room-1];
			
			%poster_session = %session;
			$poster_session{data} = [];
			$ref_session_data = $poster_session{data};
			push @{$ref_places->{sessions}}, {%poster_session};

			
			$state_in_poster = 1;
			next;
		}
		# DAY > ROOM > SESS
		elsif($line =~ /^午[前後].*\((\d+):(\d+)～(\d+):(\d+)\)(.*)$/) {
			my($st_h, $st_m, $et_h, $et_m) = ($1,$2,$3,$4);
			#$session{st_h} = $1;
			#$session{st_m} = $2;
			#$session{et_h} = $3;
			#$session{et_m} = $4;
			my $tmp = $5;
			
			if($tmp =~ /［([^\]]+)\］　　座長 (.*)　　副座長 (.*)$/) {
				$session{theme} = $1;
				$session{zacho} = $2;
				$session{sub_z} = $3;
			} elsif ($tmp =~ /　　座長 (.*)　　副座長 (.*)$/){
				$session{theme} = $m_room_theme;
				$session{zacho} = $1;
				$session{sub_z} = $2;
			}

			#$session{start} = sprintf("%02d:%02d", $session{st_h}, $session{st_m});
			#$session{end}   = sprintf("%02d:%02d", $session{et_h}, $session{et_m});
			$session{start} = sprintf("%02d:%02d", $st_h, $st_m);
			$session{end}   = sprintf("%02d:%02d", $et_h, $et_m);
			$session{data}  = [];
			
			$ref_session_data = $session{data};
			
			push @{$ref_places->{sessions}}, {%session} if($state_in_poster == 0);
			
			next;
		}
		# DAY > ROOM > SESS > DATA
		elsif($line =~ /^(\d-[0-9QPRS]{1,2}-\d{1,2})\s/) {
#			if($state_in_poster) {
#				push @{$poster_session{data}}, {id => $1};
#			} else {
#				push @{$session{data}}, {id => $1};
#			}
			push @{$ref_session_data}, {id => $1};
			next;
		}
	}
}

sub output_session_data_raw {
	my $lines = shift;
	
	my $m_day  = "";
	my $m_room = "";
	
	foreach my $line ( @{$lines} ) {
		#print "||" . $line . "\n";
		# DAY
		if($line =~ /^第(.*)日　/) {
			$m_day = utf8_zen2han($1);
			
			print join("\t", "DAY", $m_day) . "\n";
			next;
		}
		# > ROOM
		elsif($line =~ /^　(.+会場)　　(.*)/) {
			$m_room = $1;
			print "\t".join("\t", "ROOM", $1, $2) . "\n";
			next;
		}
		elsif($line =~ /^ポスター室(.)（/) {
			my $room = $1;
			$room =~ tr/①②③④/1234/;
			#print "■ PosterHeader: day = |$cur_day|, room = |$room|\n";
			
			#my $place_id = $cur_day . "P" . $room;
			print "\t\t".join("\t", "POSTER", $room) . "\n";
			next;
		}
		# > > SESS
		elsif($line =~ /^午[前後].*\((\d+):(\d+)～(\d+):(\d+)\)(.*)$/) {
			#print "■ start = |$1:$2|, end = |$3:$4|, $5\n";
			#print join("\t", "SESSION", $1, $2, $3, $4, $5) . "\n";
			
			print "\t\t".join("\t", "SESS", $1, $2, $3, $4) . "\t";
			my $tmp = $5;
			if($tmp =~ /［([^\]]+)\］　　座長 (.*)　　副座長 (.*)$/) {
				print join("\t", $1, $2, $3) . "\n";
			} elsif ($tmp =~ /　　座長 (.*)　　副座長 (.*)$/){
				print join("\t", "*****", $1, $2) . "\n";
			}
			
			next;
		}
		elsif($line =~ /^(\d-[0-9QPRS]{1,2}-\d{1,2})\s/) {
			print "\t\t\t", $1 . "\n";
			next;
		}
	}
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
