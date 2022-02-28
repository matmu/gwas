#!/usr/bin/perl

use strict;
use warnings;

if (!defined $ARGV[0] || !defined $ARGV[1]){
	
	print STDERR "Arguments required: raw_dir output_dir\n";

	exit(0);
}

my ($raw_dir, $output_dir) = @ARGV;

die "Directory '$raw_dir' does not exist\n" if(!-e $raw_dir);
die "Directory '$output_dir' does not exist\n" if(!-e $output_dir);

my $legend = "/matthias/2018-05-28_-_grs_wienbergen/1000GP3/1000GP_Phase3_combined.legend";  die if (!-e $legend);
my $vcfparse = "vcfparse"; 
my $ic = "/nfshome/munz/IC/ic.pl";  die if (!-e $ic);

system("$vcfparse -d $raw_dir -o $output_dir");
system("$ic -d $output_dir -r $legend -g -p EUR -o $output_dir");




