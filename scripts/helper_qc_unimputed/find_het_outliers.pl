#!/usr/bin/perl


use strict;
use warnings;
use File::Basename;
use Scalar::Util qw(looks_like_number);


if (!defined $ARGV[0] || !defined $ARGV[1] || !defined $ARGV[2]){
	print STDERR "Arguments required: input_file output_file n_sd\n";
	exit(0);
}


my ($input_file, $output_file, $n_sd) = @ARGV;

die if (!-e $input_file);
die if (!-e dirname($output_file));
die if (!looks_like_number($n_sd));


my $script = dirname($0)."/find_het_outliers.R";


print "cat $script | R --slave --args $input_file $output_file $n_sd\n";
system("cat $script | R --slave --args $input_file $output_file $n_sd");
