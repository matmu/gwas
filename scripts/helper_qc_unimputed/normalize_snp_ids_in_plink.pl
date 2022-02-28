#!/usr/bin/perl


use lib('/home/munz/workspace/perl_modules');


use strict;
use warnings;
use File::Reader;
 use Scalar::Util qw(looks_like_number);
 

if (!defined $ARGV[0] || !defined $ARGV[1] || !defined $ARGV[2] || !defined $ARGV[3] || !defined $ARGV[4]){
	print STDERR "Arguments required: input_file output_file mapping_file max_length keep_rsids\n";
	exit(0);
}

my $input_file = $ARGV[0]; die if (!-e $input_file);
my $output_file = $ARGV[1];
my $mapping_file = $ARGV[2];
my $max_length = $ARGV[3];  die if(!looks_like_number($max_length));
my $keep_rsids = $ARGV[4]; die if(!looks_like_number($keep_rsids) && !($keep_rsids == 1 || $keep_rsids == 0));


my @chars = ("A".."Z", "a".."z", 0..9);

open(OUT, ">".$output_file) or die "Cannot open file '$output_file': $!\n";
open(OUT2, ">".$mapping_file) or die "Cannot open file '$mapping_file': $!\n";
my $reader = File::Reader -> new($input_file);
while ($reader -> has_next()){
	
	my @data = $reader -> next();
	
	my $chr = $data[0];
	my $rsid = $data[1];
	my $cm = $data[2];
	my $pos = $data[3];
	my $a1 = $data[4];
	my $a2 = $data[5];
	
	
	my $snp_id;
	if($keep_rsids == 1 && $rsid =~ /^rs[0-9]+$/){
		$snp_id = $rsid;
	}
	else {
		$snp_id	 = $chr.":".$pos.":".join(":", sort ($a1, $a2));
	
		if(length($snp_id) > $max_length){
			my $sub = substr($snp_id, 0, $max_length-10);
			$snp_id .= $chars[rand @chars] for 1..10;
		}
	}
	
	
	print OUT2 $snp_id."\t".$snp_id."\n";
	
	$data[1] = $snp_id;
	
	print OUT join(" ", @data)."\n";
}
close OUT;
close OUT2;
