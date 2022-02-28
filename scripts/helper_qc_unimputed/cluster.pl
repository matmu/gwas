#!/usr/bin/perl


use lib('/home/munz/workspace/perl_modules');


use strict;
use warnings;
use File::Reader;
use Scalar::Util qw(looks_like_number);
use Math::Round qw(nearest);


if (!defined $ARGV[0] || !defined $ARGV[1] || !defined $ARGV[2] || !defined $ARGV[3] || !defined $ARGV[4] || !defined $ARGV[5] || !defined $ARGV[6] || !defined $ARGV[7] || !defined $ARGV[8] || !defined $ARGV[9]){
	print STDERR "Arguments required: input_file max_dist p_threshold min_snps chr_col_name pos_col_name p_col_name output_file_p-sorted output_file_pos-sorted output_file_cluster\n";
	exit(0);
}


my ($input_file, $max_dist, $p_threshold, $min_snps, $chr_col_name, $pos_col_name, $p_col_name, $output_file, $output_file2, $output_file3) = @ARGV;

die if(!-e $input_file);
die if(!looks_like_number($max_dist));
die if(!looks_like_number($p_threshold));
die if(!looks_like_number($min_snps));

print "Input file: $input_file\n";
print "Max distance between neighboring SNPs in cluster: $max_dist\n";
print "P threshold: $p_threshold\n";
print "Min SNPs per cluster: $min_snps\n";
print "Column names: $chr_col_name, $pos_col_name, $p_col_name\n";
print "Output file p-sorted: $output_file\n";
print "Output file pos-sorted: $output_file2\n";
print "Output file cluster info: $output_file3\n";


my %chr2pos2ids;
my %id2p;
my %id2pos;
my %id2chr;


print "...read SNPs with p value <".$p_threshold."\n";
my $reader = File::Reader -> new($input_file, {'has_header' => 1});
my ($header, $header_inv, $header_mult) = $reader -> get_header();
die "Column $chr_col_name doesn't exist in '$input_file'\n" if (!exists(${$header}{$chr_col_name}));
die "Column $pos_col_name doesn't exist in '$input_file'\n" if (!exists(${$header}{$pos_col_name}));
die "Column $p_col_name doesn't exist in '$input_file'\n" if (!exists(${$header}{$p_col_name}));
while ($reader -> has_next()){
	
	my @row = $reader -> next();
	
	
	my ($id, $chr, $pos, $p) = (join("\t", @row), $row[${$header_mult}{$chr_col_name}[0]], $row[${$header_mult}{$pos_col_name}[0]], $row[${$header_mult}{$p_col_name}[0]]);
	
	next if (!looks_like_number($p));
	
	if ($p < $p_threshold){
		
		print STDERR "Multiple SNPs at $chr:$pos\n" if (exists($chr2pos2ids{$chr}) && exists($chr2pos2ids{$chr}{$pos}));
		die if (exists($id2p{$id}));
		
		push(@{$chr2pos2ids{$chr}{$pos}}, $id);
		$id2p{$id} = $p;
		$id2chr{$id} = $chr;
		$id2pos{$id} = $pos;
	}
}
my $n_snps = keys(%id2p);
print "\tfound $n_snps with p < $p_threshold\n";
#foreach my $id (keys(%id2p)){
#	print $id."\n";
#};


print "...cluster SNPs with max distance between neighboring SNPs of ".$max_dist."bp. Discard cluster with less than $min_snps SNPs having p < $p_threshold\n";
my %cluster2ids;
my %cluster2min_max_pos;
foreach my $chr (sort (keys(%chr2pos2ids))){
	
	my @cluster;
	my $current_snp;
	my $current_pos;
	my $start_pos;
	
	foreach my $pos (sort {$a <=> $b} (keys(%{$chr2pos2ids{$chr}}))){
		foreach my $id (sort @{$chr2pos2ids{$chr}{$pos}}){
					
			if (!defined $current_snp){
				$current_snp = $id;
				$current_pos = $pos;
				@cluster = ($id);
				$start_pos = $pos;
			}
			elsif ($pos-$current_pos <= $max_dist){
				$current_snp = $id;
				$current_pos = $pos;
				push(@cluster, $id);
			}
			else {
				my @closed = @cluster;
				$cluster2ids{$chr."_".$current_pos} = \@closed  if (@closed >= $min_snps);
				$cluster2min_max_pos{$chr."_".$current_pos} = [$chr, $start_pos, $current_pos] if (@closed >= $min_snps);
				
				$current_snp = $id;
				$current_pos = $pos;
				@cluster = ($id);
				$start_pos = $pos;
			}
		}
	}
	
	$cluster2ids{$chr."_".$current_pos} = \@cluster if (@cluster >= $min_snps);
	$cluster2min_max_pos{$chr."_".$current_pos} = [$chr, $start_pos, $current_pos]  if (@cluster >= $min_snps);
}
my $n_clusters = keys(%cluster2ids);
print "\t$n_clusters clusters found\n";


print "...get top SNP per cluster and write to '$output_file3'\n";
my %result_ids;
open(OUT, ">".$output_file3) or die "Cannot open file '$output_file3': $!\n";
print OUT join("\t", ("cluster_id", "chr", "start", "end", "span_mb", "n_snps", "p_threshold", "min_p"))."\n";

foreach my $cluster (sort keys(%cluster2ids)){
	
	my @ids = @{$cluster2ids{$cluster}};
	my $n_ids = @ids;
	
	my ($chr, $min_pos, $max_pos) = @{$cluster2min_max_pos{$cluster}};
	my $span_mb = nearest(.01, ($max_pos - $min_pos) / 1000000); 
	
	my $top_snp;
	my $min_p;
	foreach my $id (@ids){
		
		if (!defined $top_snp){
			$top_snp = $id;
			$min_p = $id2p{$id};
		}
		elsif($min_p > $id2p{$id}) {
			$top_snp = $id;
			$min_p = $id2p{$id};
		}
	}
	
	die "SNP $top_snp exists in multiple clusters, e.g. cluster $cluster" if (exists($result_ids{$top_snp}));
	
	
	print "Cluster $chr:$min_pos-$max_pos ($span_mb MB) contains $n_ids SNP(s) with p < $p_threshold (min p = $min_p)\n";
	print OUT join("\t", ("$chr:$min_pos-$max_pos", $chr, $min_pos, $max_pos, $span_mb, $n_ids, $p_threshold, $min_p))."\n";
	
	
	$result_ids{$top_snp} = 1;
}
close OUT;

my $n_topsnps = keys(%result_ids);
print "\t".$n_topsnps." top SNPs\n";


print "...sort by p value and write to $output_file\n";
open(OUT, ">".$output_file) or die "Cannot open file '$output_file': $!\n";
my @header_string;
push(@header_string, ${$header_inv}{$_}) for sort {$a <=> $b} keys(%{$header_inv});
print OUT join("\t", @header_string)."\n";
my @sorted_by_pval = sort {$id2p{$a} <=> $id2p{$b}} keys(%result_ids);
print OUT $_."\n" for @sorted_by_pval;
close OUT;


print "...sort by position and write to $output_file2\n";
open(OUT, ">".$output_file2) or die "Cannot open file '$output_file2': $!\n";
print OUT join("\t", @header_string)."\n";
my @sorted_by_pos = sort {$id2chr{$a} <=> $id2chr{$b} ||$id2pos{$a} <=> $id2pos{$b}} keys(%result_ids);
print OUT $_."\n" for @sorted_by_pos;
close OUT;

