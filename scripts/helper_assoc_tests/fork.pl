#!/usr/bin/perl


use lib('/nfshome/munz/lib/perl5');
use lib('/nfshome/munz/workspace/perl_modules');


use strict;
use warnings;
use Parallel::SystemFork;


if (!defined $ARGV[0] || !defined $ARGV[1]){
	print STDERR "Arguments required: n_forks cmd1 cmd2 ...\n";
	exit(0);
}

my ($n_forks, @cmds) = @ARGV;

my $forkmanager = Parallel::SystemFork -> new();
$forkmanager -> add_job($_) for @cmds;
$forkmanager -> run_jobs($n_forks);
$forkmanager -> wait();
