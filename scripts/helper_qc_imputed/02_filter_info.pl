#!/usr/bin/perl


use strict;
use warnings;
use Parallel::ForkManager;

if (!defined $ARGV[0] || !defined $ARGV[1] || !defined $ARGV[2] || !defined $ARGV[3] || !defined $ARGV[4]){
	
	print STDERR "Arguments required: raw_dir output_dir cores info_thresh maf_thresh\n";

	exit(0);
}

my ($raw_dir, $output_dir, $cores, $info_thresh, $maf_thresh) = @ARGV;

die "Directory '$raw_dir' does not exist\n" if(!-e $raw_dir);
die "Directory '$output_dir' does not exist\n" if(!-e $output_dir);

my $forkmanager = Parallel::ForkManager -> new();

for(my $i=1; $i<=22; $i++){
		my $job_id = $forkmanager -> add_job(\&_filter, ["$raw_dir/$i.vcf.gz", "$output_dir/$i.vcf.gz", $info_thresh, $maf_thresh]);
}

$forkmanager -> run_jobs($cores);
$forkmanager -> wait();


sub _filter{
	my ($input_file, $output_file, $info, $maf) = @_;
	
	system("bcftools norm -m+ $input_file | bcftools view -m2 -M2 -v snps | bcftools view -Oz -i 'INFO>$info' -q $maf:minor -o $output_file");
}
