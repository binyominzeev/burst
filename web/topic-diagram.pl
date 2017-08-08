#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;

use Chart::Gnuplot;
use CGI;

# ============ parameters ============

my $first_year=1965;
my $last_year=2009;

my $full_duration=$last_year-$first_year+1;

# ============ load ============

my $q=CGI->new;
$q->import_names('GET');

my $dir="/var/www";

my $word=$GET::word;
#my $word="superstring";

my $vals=get_word_vals($word);

my @all=split/\n/, `cat $dir/years-freq.txt`;
@all=map { / /; $' } @all;

for my $i (0..$#$vals) {
	$vals->[$i]/=$all[$i];
}

my @vals=normalize_min_max(@$vals);

print "Content-type: image/png\n\n";
#print "Content-type: text/html\n\n";

my $plot="set terminal png\n".
	"#set xrange [-0.05:1.05]\n".
	"#set yrange [0.7:1000000]\n".
	"set title \"$word\"\n".
	"set xlabel \"year\"\n".
	"set ylabel \"keyword frequency (normalized)\"\n".
	"set style line 1 lc rgb '#ee0000' lt 1 lw 1 pt 7 ps 0.7   # --- red\n".
	"plot '-' using 1:2 with linespoints ls 1 notitle\n";

my $year=$first_year;
for my $val (@vals) {
	$plot.="$year\t$val\n";
	$year++;
}

$plot.="e\n";

#print $plot;

open my $GP, '|-', 'gnuplot' or die "Couldn't pipe to gnuplot: $!";
print {$GP} $plot;
close $GP;

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
	my @lines=split/\n/, `grep "^$word " $dir/freq_*.txt`;
	
	for my $line (@lines) {
		my ($year, $val)=$line=~/freq_(.*?)\.txt:.*? (.*?)$/;
		$vals[$year-$first_year]=$val;
	}
	
	return \@vals;
}
