#!/usr/bin/perl

use lib('/nfshome/munz/lib/perl5');

use strict;
use warnings;
use Sort::Key::Natural qw( natsort );

if (!defined $ARGV[0] || !defined $ARGV[1] || !defined $ARGV[2] || !defined $ARGV[3]){
	print STDERR "Arguments required: output_file has_header input_file1 input_file2 ...\n";
	exit(0);
}

my $output_file = shift @ARGV;
my $has_header = shift @ARGV; die "has_header is not '1' or '0': '$has_header'" if ($has_header ne 0 && $has_header ne 1);
my @input_files = @ARGV;

foreach (@input_files){
	die "$_ does not exist. Skip.\n" if (!-e $_);
}

my @sorted_input_files = natsort @input_files;

open(OUT, ">".$output_file) or die "Cannot open file '$output_file': $!\n";
my $print_header = 1;
foreach my $file (@sorted_input_files){
	open(IN, "<".$file) or die "Cannot open file '$file': $!\n";
	my $header = $has_header;
	while(<IN>){
		if ($header && $_ =~ /^#/){}
		elsif ($header == 1 && $print_header == 1){
			print OUT $_;
			
			$print_header = 0;
			$header = 0;
		}
		elsif($header == 1){
			$header = 0;
		}
		else {
			print OUT $_;	
		}
	}
	close IN;
}
close OUT;

