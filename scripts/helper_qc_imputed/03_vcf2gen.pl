#!/usr/bin/perl


use strict;
use warnings;
use Parallel::ForkManager;


if (!defined $ARGV[0] || !defined $ARGV[1] || !defined $ARGV[2]){
	
	print STDERR "Arguments required: input_dir output_dir cores\n";

	exit(0);
}

my ($input_dir, $output_dir, $cores) = @ARGV;

die "Directory '$input_dir' does not exist\n" if(!-e $input_dir);
die "Directory '$output_dir' does not exist\n" if(!-e $output_dir);

my $forkmanager = Parallel::ForkManager -> new();

for(my $i=1; $i<=22; $i++){
		my $job_id = $forkmanager -> add_job(\&_convert, ["$input_dir/$i.vcf.gz", "$output_dir/$i"]);
}

$forkmanager -> run_jobs($cores);
$forkmanager -> wait();

sub _convert{
	my ($input_file, $output_file) = @_;
	system("bcftools convert --tag GP -g $output_file $input_file");
}
