#!/usr/bin/perl
use strict;
use warnings;

my @inputfile=qw/PR.xml PRA.xml PRB.xml PRC.xml PRD.xml PRE.xml PRI.xml PRL.xml PRSTAB.xml PRSTPER.xml RMP.xml/;

my $doi="";
my $year="";
my $author="";

open OUT, ">doi-caption.txt";
for my $inputfile (@inputfile) {
	print "$inputfile\n";
	open IN, "<$inputfile.2";
	while (<IN>) {
		chomp;
		
		if (/<article doi="10.1103\/(.*?)">/) {
			$doi=$1;
		} elsif (/<issue printdate="(.*?)-.*">/) {
			$year=$1;
		} elsif (/<surname>(.*?)<\/surname>/ && $doi ne "") {
			$author=$1;
			$doi=~/\./;
			my $journal=$`;
			
			# sajnos, sorted grep miatt, kenytelen leszek szokozt ES tabot is beiktatni
			print OUT "$doi \t$author, $journal ($year)\n";
			
			$doi="";
			$year="";
			$author="";
		}
		
	}
	close IN;
}
close OUT;
