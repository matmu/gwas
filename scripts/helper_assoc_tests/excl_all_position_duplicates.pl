#!/usr/bin/perl

use lib('/nfshome/munz/lib/perl5');

use strict;
use warnings;


if (!defined $ARGV[0] || !defined $ARGV[1]){
	print STDERR "Arguments required: output_file file1.gen file2.gen ...\n";
	exit(0);
}


# Disable buffer for STDOUT and STDERR
STDOUT -> autoflush(1);
STDERR -> autoflush(1);


my ($output_file, @gen_files) = @ARGV;
my $tmp_result = $output_file.".tmp";
foreach my $p (@gen_files){
	die "$p\n" if (!-e $p);
}


open(OUT, ">".$tmp_result) or die "Can't open file $tmp_result': %!\n";
my $i=1;
foreach my $gen (@gen_files){
	
	
	my $tmp_part = $output_file.".part$i.tmp";
	$i++;
	
	
	print "...read file '$gen' and write ID and position to '$tmp_part'\n";
	if($gen =~ /\.gz$/){
		system("zcat $gen | cut -f2,3 -d \" \" >$tmp_part");
	}
	else {
		system("cut -f2,3 -d \" \" $gen >$tmp_part");
	}


	print "...read file '$tmp_part'";
	my %pos2ids;
	my $lines=0;
	open(IN, "<".$tmp_part) or die "Can't open file '$tmp_part': %!\n";
	while(<IN>){
		chomp($_);
		my ($id, $pos) = _split($_);
		push(@{$pos2ids{$pos}}, $id);
		$lines++;
	}
	close IN;
	print ": $lines lines\n";
	

	print "...detect positions with multiple SNPs and write duplicates to '$tmp_result'\n";
	my $dups = 0;
	foreach my $pos (sort {$a <=> $b} keys(%pos2ids)){
		if (@{$pos2ids{$pos}} > 1){
			print OUT $_."\n" for @{$pos2ids{$pos}};
			$dups++;
		}
	}
	print ": found $dups duplicates\n";
	
	
	system("rm $tmp_part\n");
}
close OUT;


print "...sort and write unique IDs to '$output_file'\n";
system("sort $tmp_result | uniq >$output_file; rm $tmp_result");


sub _split {
	my ($str) = @_;
	
	if ($str =~ /\t/){
		return split(/\t/, $str, 2);
	}
	else {
		return split(" ", $str, 2);
	}
}

