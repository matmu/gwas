#!/usr/bin/perl


use lib('/home/munz/lib/perl5');
use lib('/home/munz/workspace/perl_modules');


# -----------------------------------------------
# Author: Matthias Munz
# -----------------------------------------------


use strict;
use warnings;
use File::Reader;
use Scalar::Util qw(looks_like_number);
use List::Util qw(max);


if (!defined $ARGV[0] || !defined $ARGV[1] || !defined $ARGV[2] || !defined $ARGV[3] || !defined $ARGV[4] || !defined $ARGV[5]){
	print STDERR "Arguments required: snptest_file output_file model chr thr_maf thr_info\n";
	print STDERR "Model: add, rec, dom, ...\n";
	exit(0);
}


my ($snptest_file, $output_file, $model, $chr, $thr_maf, $thr_info) = @ARGV;


die "Error: model has to be specified (add, rec, dom, ...)\n" if ($model ne "add" && $model ne "dom" && $model ne "rec");
die "'$snptest_file' doesn't exist\n" if (!-e $snptest_file);


#my ($n_all_cases, $n_all_controls) = _get_sample_size($snptest_file);
#print $n_all_cases."\n";
#print $n_all_controls."\n";
#die;

my $snptest_reader = File::Reader -> new($snptest_file, {'has_header' => 1});
my ($header, $header_inv, $header_mult) = $snptest_reader -> get_header();


#print $_."\t".${$header}{$_}."\n" for sort keys(%{$header});
#print keys(%{$header})."\n";

open(OUT, ">".$output_file) or die "Cannot open file '$output_file': $!\n";
print OUT uc "snp\trsid\tstrand\tbuild\tchr\tpos\teffect_allele\tnon_effect_allele\tminor_allele\tmajor_allele\trisk_allele\tn\tn_cases\t".
	"n_controls\tn0_cases\tn1_cases\tn2_cases\tn0_controls\tn1_controls\tn2_controls\teaf\teaf_cases\teaf_controls\t".
	"hwe_p_cases\thwe_p_controls\tmaf_all\tmaf_cases\tmaf_controls\tcall_rate_cases\tcall_rate_controls\tmodel\tave_max_post_call\tbeta\tse\tor\tl95\tu95\tp\tinfo\n";


# SNPtest header
#alternate_ids rsid chromosome position alleleA alleleB index average_maximum_posterior_call info cohort_1_AA cohort_1_AB cohort_1_BB cohort_1_NULL cohort_2_AA 
#cohort_2_AB cohort_2_BB cohort_2_NULL all_AA all_AB all_BB all_NULL all_total cases_AA cases_AB cases_BB cases_NULL cases_total controls_AA controls_AB controls_BB 
#controls_NULL controls_total all_maf cases_maf controls_maf missing_data_proportion cohort_1_hwe cohort_2_hwe cases_hwe controls_hwe het_OR het_OR_lower het_OR_upper hom_OR hom_OR_lower 
#hom_OR_upper all_OR all_OR_lower all_OR_upper frequentist_add_pvalue frequentist_add_info frequentist_add_beta_1 frequentist_add_se_1 comment


while ($snptest_reader -> has_next()){
	my @row = $snptest_reader -> next();
	
	
	# Filter MAF
	if (!defined $row[${$header}{'all_maf'}] || $row[${$header}{'all_maf'}] < $thr_maf){
		#print $row[${$header}{'all_maf'}]." vs. $thr_maf\n";
		next;
	}
	
	
	# Filter Info
	if ($row[${$header}{"frequentist_${model}_pvalue"}] eq 'NA' || ($row[${$header}{"frequentist_${model}_info"}] ne 'NA' && $row[${$header}{"frequentist_${model}_info"}] < $thr_info)){
		#print $row[${$header}{'frequentist_add_pvalue'}]."pval $row[${$header}{'frequentist_add_info'}] info\n";
		next;
	}
	
	
	# Filter OR/Beta
	if (!looks_like_number($row[${$header}{'all_OR'}]) && !looks_like_number($row[${$header}{'frequentist_${model}_beta_1'}])){
		#print "No OR nor Beta\n";
		next;
	}
	
	#print $row[${$header}{'frequentist_add_pvalue'}]."pval $row[${$header}{'frequentist_add_info'}] info\n";
	
	my $snp = $row[${$header}{'rsid'}];
	my $rsid = 'NA'; 
	my $strand = '+';
	my $build = 37;
	my $pos = $row[${$header}{'position'}];
	
	my $effect_allele = $row[${$header}{'alleleB'}];
	my $non_effect_allele = $row[${$header}{'alleleA'}];
	
	my $n = _round(0, $row[${$header}{'all_AA'}] + $row[${$header}{'all_AB'}] + $row[${$header}{'all_BB'}]);
	my $n_cases = _round(0, $row[${$header}{'cases_AA'}] + $row[${$header}{'cases_AB'}] + $row[${$header}{'cases_BB'}]);
	my $n_controls = _round(0, $row[${$header}{'controls_AA'}] + $row[${$header}{'controls_AB'}] + $row[${$header}{'controls_BB'}]);
	my $n_all_cases = $row[${$header}{'cases_total'}];
	my $n_all_controls = $row[${$header}{'controls_total'}];
	
	my $n0_cases = _round(3, $row[${$header}{'cases_AA'}]);
	my $n1_cases = _round(3, $row[${$header}{'cases_AB'}]);
	my $n2_cases = _round(3, $row[${$header}{'cases_BB'}]);
	
	my $n0_controls = _round(3, $row[${$header}{'controls_AA'}]);
	my $n1_controls = _round(3, $row[${$header}{'controls_AB'}]);
	my $n2_controls = _round(3, $row[${$header}{'controls_BB'}]);
	
	my $eaf = _round(3, ((2*$row[${$header}{'all_BB'}])+$row[${$header}{'all_AB'}])/(2*$n));
	my $eaf_cases = ($n_cases == 0) ? "NA" : _round(3, ((2*$row[${$header}{'cases_BB'}])+$row[${$header}{'cases_AB'}])/(2*$n_cases));
	my $eaf_controls = ($n_controls == 0) ? "NA" : _round(3, ((2*$row[${$header}{'controls_BB'}])+$row[${$header}{'controls_AB'}])/(2*$n_controls));
	
	my ($minor_allele, $major_allele) = ($eaf < 0.5) ? ($effect_allele, $non_effect_allele) : ($non_effect_allele, $effect_allele);
	
	my $hwe_p_cases = _round(5, $row[${$header}{'cases_hwe'}]);
	my $hwe_p_controls = _round(5, $row[${$header}{'controls_hwe'}]); # next if ($hwe_p_controls < 0.0001);
	
	my $maf_all = _round(3, $row[${$header}{'all_maf'}]);
	my $maf_cases = _round(3, $row[${$header}{'cases_maf'}]);
	my $maf_controls = _round(3, $row[${$header}{'controls_maf'}]);
	
	my $call_rate_cases = _round(2, $n_cases/$n_all_cases);
	my $call_rate_controls = _round(2, $n_controls/$n_all_controls);
	
	my $ave_max_post_call = _round(4, $row[${$header}{'average_maximum_posterior_call'}]);
	my $beta = _round(4, $row[${$header}{"frequentist_${model}_beta_1"}]);
	my $se = _round(4, $row[${$header}{"frequentist_${model}_se_1"}]);
	my $pval = $row[${$header}{"frequentist_${model}_pvalue"}];
	
	my $or = _round(4, $row[${$header}{'all_OR'}]);
	my $l95 = _round(4, $row[${$header}{'all_OR_lower'}]);
	my $u95 = _round(4, $row[${$header}{'all_OR_upper'}]);
	
	my $risk_allele = ((looks_like_number($or) && $or > 1) || (looks_like_number($beta) && $beta > 0)) ? $effect_allele : $non_effect_allele;
	
	# print $beta."\t".$all_OR."\t".$all_OR_lower."\t".$all_OR_upper."\n";
	
	# my $imputed = ($row[${$header}{'alternate_ids'}] eq '---') ? 1 : 0;
	my $info = ($row[${$header}{"frequentist_${model}_info"}] ne 'NA') ? _round(3, $row[${$header}{"frequentist_${model}_info"}]) : 'NA';
	
	
	print OUT "$snp\t$rsid\t$strand\t$build\t$chr\t$pos\t$effect_allele\t$non_effect_allele\t$minor_allele\t$major_allele\t$risk_allele\t$n\t$n_cases\t".
	"$n_controls\t$n0_cases\t$n1_cases\t$n2_cases\t$n0_controls\t$n1_controls\t$n2_controls\t$eaf\t$eaf_cases\t$eaf_controls\t".
	"$hwe_p_cases\t$hwe_p_controls\t$maf_all\t$maf_cases\t$maf_controls\t$call_rate_cases\t$call_rate_controls\t$model\t$ave_max_post_call\t$beta\t$se\t$or\t$l95\t$u95\t$pval\t$info\n";
}
close OUT;


sub _round {
	my ($n, $str) = @_;
	
	if (looks_like_number($str)){
		$str = sprintf "%.${n}f", $str;
		$str += 0;
		return $str;
	}
	else {
		return $str;
	}
}


#sub _get_sample_size {
#	my ($snptest_file) = @_;
#	
#	my $snptest_reader = File::Reader -> new($snptest_file, {'has_header' => 1});
#	my ($header, $header_inv, $header_mult) = $snptest_reader -> get_header();
#	
#	my $i = 100000;
#	
#	my (@n_cases, @n_controls);
#	while ($snptest_reader -> has_next()){
#		my @row = $snptest_reader -> next();
#		
#		#my $n_cases = _round(0, $row[${$header}{'cases_AA'}] + $row[${$header}{'cases_AB'}] + $row[${$header}{'cases_BB'}] + $row[${$header}{'cases_NULL'}]);
#		#my $n_controls = _round(0, $row[${$header}{'controls_AA'}] + $row[${$header}{'controls_AB'}] + $row[${$header}{'controls_BB'}] + $row[${$header}{'controls_NULL'}]);
#		
#		my $n_cases2 = $row[${$header}{'cases_total'}];
#		my $n_controls2 = $row[${$header}{'controls_total'}];
#		
#		
##		print $n_cases." cases\n";
##		print $n_controls." controls\n";
#		print $n_cases2." cases2\n";
#		print $n_controls2." controls2\n";
#		
#		push(@n_cases, $n_cases2);
#		push(@n_controls, $n_controls2);
#		
#		last if ($i-- <= 0);
#	}
#	
#	my ($n_all_cases, $n_all_controls) = (max(@n_cases), max(@n_controls));
#	
#	return ($n_all_cases, $n_all_controls);
#}

