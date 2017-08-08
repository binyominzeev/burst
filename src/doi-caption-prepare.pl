#!/usr/bin/perl
use strict;
use warnings;

my @inputfile=qw/PR.xml PRA.xml PRB.xml PRC.xml PRD.xml PRE.xml PRI.xml PRL.xml PRSTAB.xml PRSTPER.xml RMP.xml/;

for my $inputfile (@inputfile) {
	print "$inputfile\n";
	`perlawk.pl "s/></>\\n</g" $inputfile > $inputfile.2`;
}
