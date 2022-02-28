#!/usr/bin/perl

use strict;
use warnings;
use Parallel::ForkManager;


if (!defined $ARGV[0] || !defined $ARGV[1] || !defined $ARGV[2]){

	print STDERR "Arguments required: raw_dir output_dir cores\n";

	exit(0);
}

my ($raw_dir, $output_dir, $cores) = @ARGV;

die "Directory '$raw_dir' does not exist\n" if(!-e $raw_dir);
die "Directory '$output_dir' does not exist\n" if(!-e $output_dir);

my $af = "/matthias/2018-05-28_-_grs_wienbergen/af.vcf.gz"; die if (!-e $af);


system("bcftools concat -Oz --threads $cores -o $output_dir/all.vcf.gz $raw_dir/*vcf.gz");
system("bcftools index $output_dir/all.vcf.gz");
system("bcftools annotate -c INFO/AF -a $af $output_dir/all.vcf.gz | bcftools +af-dist | grep ^PROB >$output_dir/af-dist.txt");
system("vis_afdist.pl $output_dir/af-dist.txt $output_dir/af-dist.png");
