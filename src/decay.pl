#!/usr/bin/perl
use strict;
use warnings;

use List::Util qw(max min);
use Data::Dumper;

# ============ parameters ============

my $first_year=1965;
my $last_year=2009;

my $full_duration=$last_year-$first_year+1;
my $quarter=int($full_duration)/4;

# ============ load ============

my @all=split/\n/, `cat years-freq.txt`;
@all=map { / /; $' } @all;

my @words=split/\n/, `cat trend-boost-slopes.txt`;
@words=map { /\t/; $` } @words;

my $all_words=scalar @words;
my $i=1;

open IN, "<trend-boost-slopes.txt";
open OUT, ">decay.txt";
#open OUTDET, ">decay-detailed.txt";
open OUTINV, ">decay-inv.txt";
while (<IN>) {
	chomp;
	my ($word, $from, $to, $xdiff, $ydiff, $slope)=split/\t/, $_;
	
	print "$i/$all_words\n";
	my $vals=get_word_vals($word);
	
	for my $i (0..$#$vals) {
		$vals->[$i]/=$all[$i];
	}
	
	my @vals=normalize_min_max(@$vals);
	
	if ($full_duration-$to+$first_year >= $quarter) {
		# decay
		
		my $min_val=min(@vals[$to+1-$first_year..$#vals]);
		my $abs_decay=$vals[$to-$first_year]-$min_val;
		my $rel_decay=$abs_decay/$ydiff;
		
		print OUT "$word\t$rel_decay\n";
#		print OUTDET "$word\t$min_val\t$abs_decay\t$ydiff\t$first_year\t$to\t$rel_decay\t1\n";
	} else {
		# inverse decay

		my $max_val=max(@vals[0..$from-$first_year]);
		my $abs_decay=$max_val-$vals[$from-$first_year];
		my $rel_decay=$abs_decay/$ydiff;
		
		print OUTINV "$word\t$rel_decay\n";
#		print OUTDET "$word\t$max_val\t$abs_decay\t$ydiff\t$first_year\t$from\t$rel_decay\t2\n";
	}
	
	$i++;
}
close IN;
close OUT;
#close OUTDET;
close OUTINV;

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
