#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use List::Util qw(max min);

#my $dir="/var/www";
my $dir=".";

# ========== initialize ==========

# kulcs mindig az elso oszlopban (e szamozas szerint nulladik)
my %sources=(
	"slope" => "trend-boost-slopes:5",
	"ydiff" => "trend-boost-slopes:4",
	#"noise" => "trend-boost-slopes:7",
	"noise" => "noise:1",
	"decay" => "decay-all:1",
#	"decay" => "decay:1",
#	"decay" => "decay-inv:1",
#	"nsdis" => "trend-boost-slopes:8",
#	"grc" => "component-proportions:4",
	"all_nodes" => "component-proportions:3",
	"edge_nodes" => "component-proportions:5",
	"giant_nodes" => "component-proportions:2",
	"sources" => "component-proportions:1"
);

my $data=preload(\%sources);

for my $word (sort keys %$data) {
	my %this=%{$data->{$word}};
	$data->{$word}->{"coverage"}=$this{"sources"}/$this{"giant_nodes"};
	$data->{$word}->{"percolation"}=$this{"giant_nodes"}/$this{"edge_nodes"};
}


#save_preloaded_data($data, "bursty-data.txt", "ydiff,decay,giant_nodes");
#save_preloaded_data($data, "bursty-data-inv.txt", "ydiff,decay,giant_nodes");
save_preloaded_data($data, "bursty-data-corr.txt", "ydiff,decay,coverage,percolation");

# ========== functions ==========

sub save_preloaded_data {
	my ($data, $outfile, $fields)=@_;
	my @fields=split ",", $fields;
	
	open OUT, ">$outfile";
	for my $word (sort keys %$data) {
		print OUT "$word";
		for my $field (@fields) {
			print OUT " $data->{$word}->{$field}";
		}
		print OUT "\n";
	}
	close OUT;
}

sub my_link {
	my ($mod, $caption)=@_;
	return ($mod eq $caption ? "[ <b>$caption</b> ]":"[ <a href=\"?mod=$caption\">$caption</a> ] ");
}

sub my_resize {
	my ($orig_val, $orig_min, $orig_max, $new_min, $new_max)=@_;
	
	my $percent=($orig_val-$orig_min)/($orig_max-$orig_min);
	my $new_val=$new_min+$percent*($new_max-$new_min);
	
	return $new_val;
}

sub preload {
	my $sources=shift;
	my %data;
	
	# ==== preload files ====
	
	my %files;
	for my $key (keys %sources) {
		my ($filename, $field)=split/:/, $sources{$key};
		if (exists $files{$filename}) { next; }
		
		$files{$filename}="";
		
#		print "$key $dir/$filename.txt\n";
		
		open IN, "<$dir/$filename.txt";
		while (<IN>) {
			chomp;
			my @line=split/\t/, $_;
			my $word=shift @line;
			
			$data{$word}->{"f_$filename"}=\@line;
		}
		close IN;
	}

#print Dumper \%data;
	
	# ==== preload columns ====
	
	for my $key (keys %sources) {
		my ($filename, $field)=split/:/, $sources{$key};
		my @keys=keys %data;
		
		for my $word (@keys) {
			if (exists $data{$word}->{"f_$filename"}) {
				$data{$word}->{$key}=$data{$word}->{"f_$filename"}->[$field-1];
			} else {
				delete $data{$word};
			}
		}
	}
	
	for my $word (keys %data) {
		$data{$word}->{"random"}=rand(1);
	}
		
	return \%data;
}

sub my_sum {
	my $sum=0;
	for (@_) {
		$sum+=$_;
	}
	return $sum;
}

sub my_avg {
	my $sum=my_sum(@_);
	if ($sum == 0) { return 0; }
	return $sum/(scalar @_);
}
