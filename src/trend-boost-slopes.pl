#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;

# ============ parameters ============

my $first_year=1965;
my $last_year=2009;

my $full_duration=$last_year-$first_year+1;
my $max_year_window=int($full_duration)/2;
my $y_limit=3/4;

# ============ load ============

my @all=split/\n/, `cat years-freq.txt`;
@all=map { / /; $' } @all;

my @words=split/\n/, `cat freq-all.txt`;
@words=map { / /; $` } @words;

my $all_words=scalar @words;
my $i=1;

open OUT, ">trend-boost-slopes.txt";
for my $word (@words) {
	print "$i/$all_words\n";
	
	my $vals=get_word_vals($word);
	#my @vals=split/\n/, `grep "^$word " freq_*.txt`;
	
	for my $i (0..$#$vals) {
		$vals->[$i]/=$all[$i];
	}

	my @vals=normalize_min_max(@$vals);

	# ============ process ============

	my $max_slope=0;
	my $max_xdiff=0;
	my $max_ydiff=0;
	my $max_years=0;

	for my $year_window (2..$max_year_window) {
		for my $offset (0..$#vals-$year_window) {
			my $year_a = $first_year + $offset;
			my $year_b = $year_a + $year_window;
			
			my $years_diff = ($vals[$offset + $year_window] - $vals[$offset]);

			#if ($years_diff >= $y_limit) {
			if ($years_diff >= 1/36*$year_window + 4/9) {
				my $years_slope = $years_diff / $year_window;
				
				if ($years_slope > $max_slope) {
					$max_slope=$years_slope;
					$max_years="$year_a\t$year_b";
					$max_xdiff=$year_window;
					$max_ydiff=$years_diff;
				}
			}
		}
	}

	if ($max_xdiff > 0) {
		my $slope=$max_ydiff/$max_xdiff;
		print OUT "$word\t$max_years\t$max_xdiff\t$max_ydiff\t$slope\n";
	}
	
	$i++;
}

close OUT;

# ============ functions ============

sub normalize_min_max {
	my $min=my_min(@_);
	my $max=my_max(@_);

	if ($max == $min) {
		if ($max == 0) {
			# csupa 0-ból áll
			$max=1;
		} else {
			# csupa N-ből áll, ahol N > 1
			$min=0;
		}
	}

	my @a;
	for (@_) {
		push @a, ($_-$min)/($max-$min);
	}
	return @a;
}

sub my_min {
	my $min=100000;
	for (@_) {
		if ($_ < $min) { $min=$_; }
	}
	return $min;
}

sub my_max {
	my $max=0;
	for (@_) {
		if ($_ > $max) { $max=$_; }
	}
	return $max;
}

sub get_word_vals {
	my $word=shift;
	
	my @vals=("0") x $full_duration;
	my @lines=split/\n/, `grep "^$word " freq_*.txt`;
	
	for my $line (@lines) {
		my ($year, $val)=$line=~/freq_(.*?)\.txt:.*? (.*?)$/;
		$vals[$year-$first_year]=$val;
	}
	
	return \@vals;
}
