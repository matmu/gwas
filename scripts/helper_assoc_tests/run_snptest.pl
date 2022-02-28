#!/usr/bin/perl


use lib('/home/munz/lib/perl5');
use lib('/home/munz/workspace/perl_modules');


use strict;
use warnings;
use Parallel::SystemFork;
use File::Reader;


if (!defined $ARGV[0] || !defined $ARGV[1] || !defined $ARGV[2] || !defined $ARGV[3] || !defined $ARGV[4]){
	print STDERR "Arguments required: prefixes_file dups_file phenotype_name cov_names cores [exclude_individuals]\n";
	exit(0);
}


my ($prefixes_file, $dups_file, $phenotype_name, $cov_names, $cores, $exclude_individuals) = @ARGV;
die if (!-e $prefixes_file);
die if ($phenotype_name eq "");
if (defined $exclude_individuals && !-e $exclude_individuals){die;}


my $forkmanager = Parallel::SystemFork -> new();


print "...read config '$prefixes_file' and create jobs\n";
my $reader = File::Reader -> new($prefixes_file, {'has_header' => 0});
while ($reader -> has_next()){
	
	my @gen_sample_files = $reader -> next();
	
	my $output_file_prefix = pop(@gen_sample_files);
	
	next if ($gen_sample_files[0] =~ /^#/);
	die if (@gen_sample_files % 2 != 0);
	
	foreach (@gen_sample_files){
		die $_." doesn't exist\n" if (!-e $_);
	}
	
	my $output_file = $output_file_prefix.".out";
	my $output_log = $output_file_prefix.".log";
	
	my $job = "snptest_v2.5.2 -data ".join(" ", @gen_sample_files)." ".
					"-frequentist 1 ". 
					"-method score ".
					"-pheno $phenotype_name ".
					"-hwe -missing_code NA ".
					"-overlap ".
					"-o $output_file ".
					"-log $output_log";
					
	if(defined $dups_file && -e $dups_file){
		$job .= " -exclude_snps $dups_file";
	}
					
	if (defined $cov_names && $cov_names ne ""){
		$job .= " -cov_names $cov_names";
	}
	
	if (defined $exclude_individuals){
		$job .= " -exclude_samples $exclude_individuals";
	}
	
	print $job."\n";
	$forkmanager -> add_job($job);
}


$forkmanager -> run_jobs($cores);
$forkmanager -> wait();

