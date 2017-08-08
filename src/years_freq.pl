#!/usr/bin/perl
use strict;
use warnings;

open OUT, ">years-freq.txt";
for my $year (1965..2009) {
	my $sum=`cut -d" " -f2 freq_$year.txt | szum.pl`;
	print OUT "$year $sum";
}
close OUT;
