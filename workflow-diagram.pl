#!/usr/bin/perl
use strict;
use warnings;

use GraphViz;

# ============ parameters ============

my $dir="src";

# ============ initialize ============

my $graph=GraphViz->new(node => { label => "" }, rankdir => "LR");

# ============ process files ============

my @files=split/\n/, `ls $dir/*.pl`;

for my $file (@files) {
	# ============ collect variable initalizing values ============
	
	my @lines=split/\n/, `cat $file`;
	my @open_lines=grep { /open / && !/#/ } @lines;
	
	my %var;
	
	for my $line (@open_lines) {
		my @vars=$line=~/\$[a-z]+/g;
		for my $var (@vars) {
			$var=substr($var, 1);
			my @var_lines=grep { /\$$var/ && !/#/ } @lines;
			
			if ($var_lines[0]=~/"(.*)"/) {
				$var{$var}=$1;
			}
		}
	}
	
	# ============ draw nodes and edges ============
	
	$graph->add_node($file, fillcolor => "yellow", style => "filled", label => $file);
	
	for my $line (@open_lines) {
		$line=subst_vars($line, \%var);
		if ($line=~/<(.*)"/) {
			$graph->add_edge($1, $file);
		} elsif ($line=~/>(.*)"/) {
			$graph->add_edge($file, $1);
		}
	}
}

# ============ save diagram output ============

open OUT, ">workflow-diagram.png";
print OUT $graph->as_png;
close OUT;

# ============ functions ============

sub subst_vars {
	my ($str, $vars)=@_;
	
	my $newstr=$str;
	for my $varname (keys %$vars) {
		if ($str=~/$varname/) {
			$newstr=~s/\$$varname/$vars->{$varname}/g;
		}
	}
	
	return $newstr;
}









