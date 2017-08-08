#!/usr/bin/perl
use strict;
use warnings;

use Graph;
use GraphViz;
use CGI;

use Data::Dumper;

my $q=CGI->new;
$q->import_names('R');

my $word=$R::word;
#$word="flux";

my $dir="/var/www";
my $net_dir="/var/www/word-nodes-edges";

print "Content-type: image/png\n\n";
#print "Content-type: image/svg\nContent-disposition: attachment; filename=graph.svg\n\n";

my $g=Graph::Undirected->new;
my $g_dir=Graph->new;
my $filename="$net_dir/$word-edges.txt";

open IN, "<$filename";
while (<IN>) {
	chomp;
	my ($from, $to)=split/ /, $_;
	$g->add_edge($to, $from);
	$g_dir->add_edge($to, $from);
}
close IN;

my %sources;
my @V=$g_dir->vertices;

for my $v (@V) {
	if ($g_dir->in_degree($v) == 0) {
		$sources{$v}="";
	}
}

# ============ components ============

my @comp=$g->connected_components();
my @comp_indexes=sort { scalar @{$comp[$b]} <=> @{$comp[$a]} } (0..$#comp);

my %giant_component;
map { $giant_component{$_}="" } @{$comp[$comp_indexes[0]]};

my @graph_lines=split/\n/, `cat $filename`;
my $graph=GraphViz->new(node => { label => "" });

for my $s (keys %sources) {
	if (exists $giant_component{$s}) {
		my $caption=doi_to_caption($s);
		$graph->add_node($s, fillcolor => "yellow", style => "filled", label => $caption);
	}
}

for my $s (keys %giant_component) {
	if (!exists $sources{$s}) {
		my $caption=doi_to_caption($s);
		$graph->add_node($s, label => $caption);
	}
}

#my $graph=GraphViz->new(node => {shape => 'box'});

for my $line (@graph_lines) {
	$line=~/ /;
#	$graph->add_node($`, label => "");
#	$graph->add_node($', label => "");
}

for my $line (@graph_lines) {
	$line=~/ /;
	
	if (exists $giant_component{$'} && exists $giant_component{$`}) {
		$graph->add_edge($', $`);
	}
}

print $graph->as_png;
#print $graph->as_svg;

# ============ functions ============

sub doi_to_caption {
	my $doi=shift;
	$doi=~/\//;
	$doi=$';
	
	my $caption=`sgrep "$doi " $dir/doi-caption.txt`;
	chomp $caption;
	$caption=~/\t/;
	return $';
}
