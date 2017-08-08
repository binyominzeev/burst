#!/usr/bin/perl
use strict;
use warnings;

use Set::Scalar;
use Term::ProgressBar::Simple;

my %word_years;
my @words=split/\n/, `cat trend-boost-slopes.txt`;

my %node_words;

my $all=scalar @words;
my $i=1;

#@words=("magnetic");

for my $line (sort @words) {
	my ($word, $from, $to, $xdiff, $ydiff, $slope)=split/\t/, $line;
	#my $word=$line;
	
	print "$i/$all $word\n";
	
	my %nodes;
	my @nodes=split/\n/, `cat word-nodes-edges/$word-nodes.txt`;
	
	for my $node (@nodes) {
		$node_words{$node}->{$word}="";
	}
	$i++;
}

print "generating sets...\n";

for my $node (keys %node_words) {
	$node_words{$node}=new Set::Scalar(keys %{$node_words{$node}});
}

print "processing edges...\n";

my %word_edges;
my $progress=new Term::ProgressBar::Simple(4710548);

open IN, "<../../../archive/aps/citing_cited.csv";
while (<IN>) {
	chomp;
	my ($from, $to)=split /,/, $_;
	
	if (exists $node_words{$from} && exists $node_words{$to}) {
		my $a=$node_words{$from};
		my $b=$node_words{$to};
		my $intersection=$a*$b;
		
		for my $word ($intersection->elements) {
			$word_edges{$word}->{$from}->{$to}="";
		}
	}
	
	$progress++;
}
close IN;

$i=1;
	
for my $word (sort keys %word_edges) {
	print "$i/$all writing $word\n";
	
	open OUT, ">word-nodes-edges/$word-edges.txt";
	my %edges=%{$word_edges{$word}};
	
	for my $from (keys %edges) {
		for my $to (keys %{$edges{$from}}) {
			print OUT "$from $to\n";
		}
	}
	close OUT;
	
	$i++;
}


