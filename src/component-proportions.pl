#!/usr/bin/perl
use strict;
use warnings;

use Graph;
use Graph::Directed;

use Data::Dumper;

# ============ parameters ============

# csak a kenyelem miatt hozzafuzzuk
my %grc;
map { / /; $grc{$`}=$' } split/\n/, `cat grc.txt`;

#my $word="adsorption";
my @words=split/\n/, `cat trend-boost-slopes.txt`;

my $all=scalar @words;
my $i=1;

#@words=("magnetic");

open OUT, ">component-proportions.txt";
for my $line (sort @words) {
	my ($word, $from, $to, $xdiff, $ydiff, $slope)=split/\t/, $line;
	#my $word=$line;
	
	print "$i/$all $word\n";
	my $filename="word-nodes-edges/$word-edges.txt";
	
	if (! -e $filename) { next; }

	# ============ load ============

	my $g=Graph::Undirected->new;
	my $g_dir=Graph::Directed->new;

	# igazabol ez a nyelo, mert pont az a source, amire csak hivatkoznak, de o nem hivatkozik

	open IN, "<$filename";
	while (<IN>) {
		chomp;
		my ($from, $to)=split/ /, $_;
		
		$g->add_edge($from, $to);
		$g_dir->add_edge($from, $to);
	}
	close IN;

	# ============ components ============

	my @comp=$g->connected_components();
	my @comp_indexes=sort { scalar @{$comp[$b]} <=> @{$comp[$a]} } (0..$#comp);

	my %giant_component;
	map { $giant_component{$_}="" } @{$comp[$comp_indexes[0]]};
	my $giant_component=scalar keys %giant_component;

	my %all_sources;
	my @all_sources=$g_dir->sink_vertices(); # ez vicces sor, ld. fent
	map { $all_sources{$_}="" } @all_sources;

	my %proportions;

	my @sources=grep { exists $all_sources{$_} } keys %giant_component;
	my $sources=scalar @sources;
	
	# feltehetoen ket egymasra hivatkozo cikk
	if (@sources == 0) { next; }
	
	if (exists $grc{$word}) {
		my $all_nodes=`wc -l word-nodes-edges/$word-nodes.txt`;
		$all_nodes=~/[0-9]+/;
		$all_nodes=$&;
		$all_nodes++; # wc -l korrekcio
		
		my $edge_nodes=$g->vertices;
		
		print OUT "$word\t$sources\t$giant_component\t$all_nodes\t$grc{$word}\t$edge_nodes\n";
		#print "$word\t$sources\t$giant_component\t$all_nodes\t$grc{$word}\t$edge_nodes\n";
	}
	
	$i++;
}
close OUT;

# ============ functions ============

sub get_comp_size {
	my $string=shift;
	$string=~/\/([0-9]+)/;
	return $1;
}

sub get_source_count {
	my $string=shift;
	$string=~/([0-9]+)\//;
	return $1;
}
