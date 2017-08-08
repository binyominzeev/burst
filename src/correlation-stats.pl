#!/usr/bin/perl
use strict;
use warnings;

use Statistics::Basic qw(:all nofill);
use Statistics::RankCorrelation;

use List::Util qw/min max/;

use Data::Dumper;

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

my @test_x;
my @test_y;

my @stats=sort keys %sources;

# ========== definition ==========

#my $outfile="cover-size";
#my $outfile="perco-size";
#my $outfile="hier-size";
#my $outfile="perco-cover-2";

#my $x="percolation";
my $x="coverage";
my $y="slope";

my $outfile="corr-$x-$y";

for my $word (sort keys %$data) {
	my %this=%{$data->{$word}};
	
	push @test_x, $this{$x};
	#push @test_x, $this{$x}/$this{"giant_nodes"};
	push @test_y, $this{$y};
	#push @test_y, $this{$y}/$this{"edge_nodes"};
	
	#print "($this{$x} $this{$y})\t";
}

# ========== stats ==========

my $pearson=correlation(\@test_x, \@test_y);

my $c=Statistics::RankCorrelation->new(\@test_x, \@test_y);

my $n=$c->spearman;
my $t=$c->kendall;

print "$x-$y\n======\n";

print "Pearson: $pearson\n".
	"Spearman: $n\n".
	"Kendall: $t\n";

# ========== draw ==========

my %x_boxes;
my $box_count=20;

open TMP, ">$outfile.txt";
for my $i (0..$#test_x) {
	print TMP "$test_x[$i] $test_y[$i]\n";
	
	my $box_x=int($test_x[$i]*$box_count)/$box_count;
	push @{$x_boxes{$box_x}}, $test_y[$i];
}
close TMP;

$x_boxes{min(@test_x)}=$x_boxes{0};
delete $x_boxes{0};

open TMP, ">$outfile-avg.txt";
for my $x (sort { $a <=> $b } keys %x_boxes) {
	my $avg=my_avg(@{$x_boxes{$x}});
	print TMP "$x $avg\n";
}
close TMP;

open OUT, ">$outfile.gnuplot";
print OUT "set terminal svg\n".
	"set output \"$outfile.svg\"\n".
	
	"#set terminal postscript eps enhanced color size 3in,2.5in\n".
	"#set output '$outfile.eps'\n".
	
	"#set xrange [0.02:0.52]\n".
	"#set yrange [-0.03:0.93]\n".
	
#	"set log y\n".
	
	#"set title \"Hierarchy-Percolation correlation: 0.06\"\n".

	"set xlabel \"$x\"\n".
	"set ylabel \"$y\"\n".

	#"set xlabel \"Hierarchicalness\"\n".
	#"set ylabel \"Proportion of giant component\"\n".

	"set style line 1 lc rgb '#ee0000' lt 1 lw 1 pt 7 ps 0.5   # --- red\n".
	"set style line 2 lc rgb '#007700' lt 1 lw 2 pt 7 ps 0.7   # --- green\n".

	"plot '$outfile.txt' using 1:2 with points ls 1 notitle, \\\n".
		"'$outfile-avg.txt' using 1:2 with lines ls 2 notitle";
close OUT;
`gnuplot $outfile.gnuplot`;

# ========== functions ==========

sub preload {
	my $sources=shift;
	my %data;
	
	# ==== preload files ====
	
	my %files;
	for my $key (keys %sources) {
		my ($filename, $field)=split/:/, $sources{$key};
		if (exists $files{$filename}) { next; }
		
		$files{$filename}="";
		
		open IN, "<$filename.txt";
		while (<IN>) {
			chomp;
			my @line=split/\t/, $_;
			my $word=shift @line;
			
			$data{$word}->{"f_$filename"}=\@line;
		}
		close IN;
	}
	
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
