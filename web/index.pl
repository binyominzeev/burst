#!/usr/bin/perl
use strict;
use warnings;

use CGI;
use Data::Dumper;
use List::Util qw(max min);

my $q=CGI->new;
$q->import_names('R');

my $mod=$R::mod;

if (!$mod) {
	$mod="slope";
}

my $dir="/var/www";

# ========== initialize ==========

# kulcs mindig az elso oszlopban (e szamozas szerint nulladik)
my %sources=(
	"slope" => "trend-boost-slopes:5",
	"ydiff" => "trend-boost-slopes:4",
	#"noise" => "trend-boost-slopes:7",
	#"noise" => "noise:1",
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

# ========== definition ==========

for my $word (sort keys %$data) {
	my %this=%{$data->{$word}};
	$data->{$word}->{"coverage"}=log($this{"sources"}/$this{"giant_nodes"});
	$data->{$word}->{"percolation"}=$this{"giant_nodes"}/$this{"edge_nodes"};
	
	$data->{$word}->{"log_giant_nodes"}=log($this{"giant_nodes"});
}

print "Content-type: text/html\n\n";

my $min_font_size=6;
my $max_font_size=20;

my $size_field="log_giant_nodes";
#my $color_field="slope";
#my $color_field="coverage";
my $color_field=$mod;

print "<p>by: ".my_link($mod, "slope").
	my_link($mod, "coverage").
	my_link($mod, "percolation").
	my_link($mod, "decay")."</p>\n\n";

# ======== filter =========

#my @noisy_keys=grep { $data->{$_}->{"noise"} >= 0.25 } keys %$data;
#my @noisy_keys=grep { $data->{$_}->{"noise"} >= 0.15 } keys %$data;
#map { delete $data->{$_} } @noisy_keys;

#my @not_bursty_keys=grep { $data->{$_}->{"slope"} < 0.7 } keys %$data;
#map { delete $data->{$_} } @not_bursty_keys;

my @noisy_keys=grep { $data->{$_}->{"decay"} >= 0.5 } keys %$data;
map { delete $data->{$_} } @noisy_keys;

# ======== filter end =========

my @sizes=map { $data->{$_}->{$size_field} }
	grep { exists $data->{$_}->{$size_field} } keys %$data;

my $min_sizes=min(@sizes);
my $max_sizes=max(@sizes);

my @colors=map { $data->{$_}->{$color_field} } 
	grep { exists $data->{$_}->{$color_field} } keys %$data;

my $min_colors=min(@colors);
my $max_colors=max(@colors);

print "<p>$min_colors-$max_colors</p>\n";

print "<div style=\"display: block; width: 800px; text-align: justify;\">\n";

for my $word (sort keys %$data) {
	my %this=%{$data->{$word}};
	
	my $size_val=my_resize($this{$size_field}, $min_sizes, $max_sizes, $min_font_size, $max_font_size);
	my $color_val=my_resize($this{$color_field}, $min_colors, $max_colors, 0, 255);
	
	if ($mod eq "coverage") {
		$color_val=255-$color_val;
	}
	
	my $color=my_rgb($color_val, 255-$color_val, "50");
	
	if ($this{'giant_nodes'} <= 60) {
		print "<a href=\"article-cloud.pl?word=$word\" style=\"text-decoration: none\"><span style=\"font-size: $size_val"."pt; color: $color\">$word</span></a> ";
	} else {
		print "<span style=\"font-size: $size_val"."pt; color: $color\">$word</span> ";
	}
}

print "</div>";

# ========== functions ==========

sub my_rgb {
	my ($r, $g, $b)=@_;
	
	($r, $g, $b)=map { max($_-30, 0) } ($r, $g, $b);
	
	$r=sprintf("%.2X", $r);
	$g=sprintf("%.2X", $g);
	$b=sprintf("%.2X", $b);
	
	return "#$r$g$b";
}

sub my_link {
	my ($mod, $caption)=@_;
	return ($mod eq $caption ? "[ <b>$caption</b> ]":"[ <a href=\"?mod=$caption\">$caption</a> ] ");
}

sub my_resize {
	my ($orig_val, $orig_min, $orig_max, $new_min, $new_max)=@_;
	
	my $percent=($orig_val-$orig_min)/($orig_max-$orig_min);
	my $new_val=$new_min+$percent*($new_max-$new_min);
	
	return $new_val;
}

sub preload {
	my $sources=shift;
	my %data;
	
	# ==== preload files ====
	
	my %files;
	for my $key (keys %sources) {
		my ($filename, $field)=split/:/, $sources{$key};
		if (exists $files{$filename}) { next; }
		
		$files{$filename}="";
		
		open IN, "<$dir/$filename.txt";
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
