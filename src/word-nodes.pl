#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;

# ============ load boosting words ============

my %word_years;
my @words=split/\n/, `cat trend-boost-slopes.txt`;

for my $line (@words) {
	my ($word, $from, $to, $xdiff, $ydiff, $slope)=split/\t/, $line;
	$word_years{$word}="$from-$to";
}

#$word_years{"magnetic"}="1986-1991";

# ============ process dataset ============

my %word_nodes;

open IN, "<../../../archive/aps/aps_doi_year_title.txt";
while (<IN>) {
	chomp;
	my @all=split/ /, $_;
	
	my $doi=shift @all;
	my $year=shift @all;
	my $title=join " ", @all;
	
	my @words=$title=~/[a-zA-Z]+/g;
	@words=map { lc $_ } @words;

	for my $word (@words) {
		if (exists $word_years{$word}) {
			if (substr($word_years{$word}, 0, 4) <= $year && $year <= substr($word_years{$word}, -4)) {
				$word_nodes{$word}->{$doi}="";
				last;
			}
		}
	}
}
close IN;

# ============ save result ============

for my $word (sort keys %word_nodes) {
	open OUT, ">word-nodes-edges/$word-nodes.txt";
	print OUT join "\n", sort keys %{$word_nodes{$word}};
	close OUT;
}
