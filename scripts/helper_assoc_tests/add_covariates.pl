#!/usr/bin/perl

use lib('/home/munz/lib/perl5');

use strict;
use warnings;

if (!defined $ARGV[0] || !defined $ARGV[1] || !defined $ARGV[2]){
	print STDERR "Arguments required: covariates.txt input_file output_file\n";
	exit(0);
}


my ($covariates, $input_file, $output_file) = @ARGV; 
die if (!-e $covariates);
die if (!-e $input_file);


# New covariates
my ($fam_id2ind_id2cov2val, $col2header, $var_types, $order2id, $header) = _read_sample_file($covariates);


# Update sample files
print "...update sample file\n";
my ($b_fam_id2ind_id2cov2val, $b_col2header, $b_var_types, $b_order2id, $b_header) = _read_sample_file($input_file);


my $new_sample_file = $output_file;
print "...update file '$input_file'. Output file is '$new_sample_file'\n";
open(OUT, ">".$new_sample_file) or die "Cannot open file. $!\n";


# Header
my @new_vars;
my @new_header;
foreach (sort {$a <=> $b} keys(%{$b_col2header})){
	push(@new_header, ${$b_col2header}{$_});
}
foreach my $col (sort {$a <=> $b} keys(%{$col2header})){
	if (!exists(${$b_header}{${$col2header}{$col}})){
		push(@new_header, ${$col2header}{$col});
		push(@new_vars, $col);
	}
}
print OUT join(" ", @new_header)."\n";


# Variable type
my @vars;
foreach my $col (sort {$a <=> $b} keys(%{$b_var_types})){
	push(@vars, ${$b_var_types}{$col});
}
foreach my $col (@new_vars){
	push(@vars, ${$var_types}{$col});
}
print OUT join(" ", @vars)."\n";


# Data
foreach my $order (sort {$a <=> $b} keys(%{$b_order2id})){
	my ($fam_id, $ind_id) = @{${$b_order2id}{$order}};
	
	my @row = ($fam_id, $ind_id);
	
	
	# Update existing columns in sample
	foreach my $col (sort {$a <=> $b} keys(%{$b_col2header})){
		
		next if ($col <= 1);
		
		if (!exists(${$header}{${$b_col2header}{$col}})){
			push(@row, ${$b_fam_id2ind_id2cov2val}{$fam_id}{$ind_id}{${$b_col2header}{$col}});
			
			#print ${$b_col2header}{$col}."\told\t".${$b_fam_id2ind_id2cov2val}{$fam_id}{$ind_id}{${$b_col2header}{$col}}."\n";
		}
		else {
			
			if (!exists(${$fam_id2ind_id2cov2val}{$fam_id}) || !exists(${$fam_id2ind_id2cov2val}{$fam_id}{$ind_id})){
				print STDERR "ID_1 $fam_id ID_2 $ind_id not in file '$covariates'. Write 'NA' instead\n";
				push(@row, 'NA');
			}
			else {
				push(@row, ${$fam_id2ind_id2cov2val}{$fam_id}{$ind_id}{${$b_col2header}{$col}});
			}
			
			#print ${$b_col2header}{$col}."\tnew\t".${$fam_id2ind_id2cov2val}{$fam_id}{$ind_id}{${$b_col2header}{$col}}."\n";
		}
	}
	
	
	# Add new columns to sample file
	my $done = 0;
	foreach my $col (sort {$a <=> $b} keys(%{$col2header})){
		if (!exists(${$b_header}{${$col2header}{$col}})){
			
			if (!exists(${$fam_id2ind_id2cov2val}{$fam_id}) || !exists(${$fam_id2ind_id2cov2val}{$fam_id}{$ind_id})){
				print STDERR "ID_1 $fam_id ID_2 $ind_id not in file '$covariates'. Write 'NA' instead\n" if ($done == 0);
				push(@row, 'NA');
				$done = 1;
			}
			else {
				push(@row, ${$fam_id2ind_id2cov2val}{$fam_id}{$ind_id}{${$col2header}{$col}});	
			}
		}
	}
	
	print OUT join(" ", _replace_undef(@row))."\n";
}


close OUT;


sub _replace_undef {
	my @data = @_;
	
	my @result;
	
	foreach my $d (@data){
		if (!defined $d || $d eq ""){
			push(@result, "NA");
		}
		else {
			push(@result, $d);
		}
	}
	
	return @result;
}


sub _read_sample_file {
	my ($file) = @_;
	
	
	my %fam_id2ind_id2cov2val;
	my %header;
	my %col2header;
	my %var_types;
	my $header = 1;
	my $var_type = 1;
	my $order = 0;
	my %order2id;
	open(IN, "<".$file) or die "Can't open file '$file': %!\n";
	while(<IN>){
		chomp($_);
		
		if ($header){
			my @header = _split($_);
			
			my $i=0;
			foreach my $h (@header){
				$col2header{$i++} = $h;
				$header{$h} = 1;
			}
			
			die "Header ID_1 doesn't exist in '$file'" if (!exists($header{"ID_1"}));
			die "Header ID_2 doesn't exist in '$file'" if (!exists($header{"ID_2"}));
			
			$header = 0;
		}
		elsif ($var_type){
			my @types = _split($_);
			
			my $i=0;
			foreach (@types){
				$var_types{$i++} = uc $_;
			}
			
			$var_type = 0;
		}
		else {
			my @row = _split($_);
			my ($fam_id, $ind_id, @cov) = @row;
			# print $fam_id."\t".$ind_id."\t".join("\t", @cov)."\n";
			
			for (my $i=0; $i<@cov; $i++){
				$fam_id2ind_id2cov2val{$fam_id}{$ind_id}{$col2header{$i+2}} = $cov[$i];
			}
			
			$order2id{$order++} = [$fam_id, $ind_id];
		}
	}
	close IN;
	
	
	return (\%fam_id2ind_id2cov2val, \%col2header, \%var_types, \%order2id, \%header);
}


sub _split {
	my ($str) = @_;
	
	if ($str =~ /\t/){
		return split(/\t/, $str);
	}
	else {
		return split(" ", $str);
	}
}


sub _remove_ext {
	my ($filename) = @_;
	
	$filename =~ s/(.*)\.[^.]+$//;

	return $1;
}

