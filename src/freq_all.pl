#!/usr/bin/perl
use strict;
use warnings;

my %word_freq;

for my $year (1965..2009) {
	open IN, "<freq_$year.txt";
	while (<IN>) {
		chomp;

		my ($word, $freq)=split/ /, $_;
		if ($freq < 20) { last; }
		#if ($freq < 135) { last; }

		$word_freq{$word}+=$freq;
	}
	close IN;
}

open OUT, ">freq-all.txt";
for my $word (sort { $word_freq{$b} <=> $word_freq{$a} } keys %word_freq) {
	print OUT "$word $word_freq{$word}\n";
}
close OUT;
