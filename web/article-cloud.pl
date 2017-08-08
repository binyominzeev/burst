#!/usr/bin/perl
use strict;
use warnings;

use Graph;
use GraphViz;

use CGI;
use Data::Dumper;
use List::Util qw(max min);

my $q=CGI->new;
$q->import_names('R');

my $word=$R::word;
my $net_dir="/var/www/word-nodes-edges";

if (!$word) {
	$word="cluster";
}

my $dir="/var/www";

# ========== initialize ==========

print "Content-type: text/html\n\n";

my $articles=word_article_levels($word);

my $min_font_size=8;
my $max_font_size=30;

my $size_field="indeg";
my $color_field="level";

#print "<p>by: ".my_link($mod, "slope").
#	my_link($mod, "coverage").
#	my_link($mod, "percolation")."</p>\n\n";

my @sizes=map { $articles->{$_}->{$size_field} }
	grep { exists $articles->{$_}->{$size_field} } keys %$articles;

my $min_sizes=min(@sizes);
my $max_sizes=max(@sizes);

my @colors=map { $articles->{$_}->{$color_field} } 
	grep { exists $articles->{$_}->{$color_field} } keys %$articles;

my $min_colors=min(@colors);
my $max_colors=max(@colors);

# ========== definition ==========

print "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n".
	"<html xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"en-US\">\n".
	"<head profile=\"http://gmpg.org/xfn/11\">\n".
	"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\"/>\n".
	"</head>\n".
	"<body>\n".
	"<div style=\"display: block; width: 600px; text-align: justify;\">\n";

for my $doi (sort { $articles->{$a}->{"caption"} cmp $articles->{$b}->{"caption"} } keys %$articles) {
	my %this=%{$articles->{$doi}};
	
	if (exists $this{$color_field}) {
		my $size_val=my_resize($this{$size_field}, $min_sizes, $max_sizes, $min_font_size, $max_font_size);
		my $color_val=my_resize($this{$color_field}, $min_colors, $max_colors, 0, 255);
		my $inv_color_val=sprintf("%.2X", 255-$color_val);
		
		$color_val=sprintf("%.2X", $color_val);
		
		my $color="#".$color_val."00".$inv_color_val;
		
		print "<a href=\"http://dx.doi.org/10.1103/$doi\" style=\"text-decoration: none\"><span style=\"font-size: $size_val"."pt; color: $color;".(exists $this{"src"}?" border: darkorange 1px solid;":"")."\">".$this{"caption"}."</span></a> ";
	}
}

print "</div>\n<div style=\"display: block; margin-top: 10px\">".
	"<p><img src=\"graph-browser.pl?word=$word\"></p>\n".
	"<p><img src=\"topic-diagram.pl?word=$word\"></p></div>".
	"</body></html>";

# ========== functions ==========

sub my_link {
	my ($mod, $caption)=@_;
	return ($mod eq $caption ? "[ <b>$caption</b> ]":"[ <a href=\"?mod=$caption\">$caption</a> ] ");
}

sub my_resize {
	my ($orig_val, $orig_min, $orig_max, $new_min, $new_max)=@_;
	
	my $percent=($orig_val-$orig_min)/($orig_max-$orig_min);
	my $new_val=$new_min+$percent*($new_max-$new_min);
	
#	print "($orig_val, $orig_min, $orig_max, $new_min, $new_max) -> $new_val\n";
	
	return $new_val;
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

sub word_article_levels {
	my $word=shift;
	
	my $g=Graph::Undirected->new;
	my $g_dir=Graph->new;
	my $filename="$net_dir/$word-edges.txt";
	
	my %articles;

	open IN, "<$filename";
	while (<IN>) {
		chomp;
		my ($from, $to)=split/ /, $_;

		$from=~/\//;
		$from=$';

		$to=~/\//;
		$to=$';

		$g->add_edge($to, $from);
		$g_dir->add_edge($to, $from);
		
		$articles{$to}->{"indeg"}++;
		if (!exists $articles{$from}->{"indeg"}) {
			$articles{$from}->{"indeg"}=0;
		}
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

	my $graph_lines=`cat $filename`;
	$graph_lines=~s/10.1103\///g;
	my @graph_lines=split/\n/, $graph_lines;
	
	my $graph=GraphViz->new(node => { label => "" });

	for my $s (keys %sources) {
		if (exists $giant_component{$s}) {
			$articles{$s}->{"src"}="1";
		}
	}

	for my $line (@graph_lines) {
		$line=~/ /;
		
		if (exists $giant_component{$'} && exists $giant_component{$`}) {
			$graph->add_edge($', $`);
		}
	}

	# ============ process Y-levels based on GraphViz SVG ============

	my $svg=$graph->as_svg;

	my %y_levels;
	while ($svg=~/<text .*? y="(.*?)" .*?>(.*?)<\/text>/g) {
		$articles{$2}->{"level"}=$1;
		$y_levels{$1}="";
	}
	
	my $i=1;
	
	for my $y (sort { $b <=> $a } keys %y_levels) {
		$y_levels{$y}=$i++;
	}

	$ENV{'LC_ALL'}='C';	
	for my $article (keys %articles) {
		if ($articles{$article}->{"level"}) {
			$articles{$article}->{"level"}=$y_levels{$articles{$article}->{"level"}};
		}

		my $caption=`sgrep "$article " $dir/doi-caption.txt`;
		
		#print STDERR "sgrep "$article " $dir/doi-caption.txt\n";
		#print STDERR "$caption\n";
		
		chomp $caption;
		$caption=~/\t/;
		$articles{$article}->{"caption"}=$';
	}

	#print Dumper \%articles;
	
	return \%articles;
}
