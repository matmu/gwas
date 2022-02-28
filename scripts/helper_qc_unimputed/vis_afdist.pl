#!/usr/bin/perl


use strict;
use warnings;
use File::Basename;


if (!defined $ARGV[0] || !defined $ARGV[1]){
	print STDERR "Arguments required: input_file output_file\n";
	exit(0);
}


my ($input_file, $output_file) = @ARGV;

die if (!-e $input_file);
die if (!-e dirname($output_file));


my $script = dirname($0)."/vis_afdist.R";


print "cat $script | R --slave --args $input_file $output_file\n";
system("cat $script | R --slave --args $input_file $output_file");

