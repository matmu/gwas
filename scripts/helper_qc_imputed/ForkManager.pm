package Parallel::ForkManager;

use strict;
use warnings;
use Benchmark;


# -----------------------------------------------
# Author: Matthias Munz
# -----------------------------------------------


# -----------------------------------------------
# Constructor
sub new {
# -----------------------------------------------
	my ($class) = @_;
	
	my $self = {};
	
	$self -> {'pids'} = {};
	$self -> {'job_increment'} = 0;
	$self -> {'routines'} = {};
	$self -> {'pars'} = {};
	$self -> {'finished_jobs'} = [];
	
	bless($self, $class);
	
	$SIG{CHLD} = 'IGNORE';
	
	return($self);
}


# -----------------------------------------------
sub add_job {
# -----------------------------------------------	
	my ($self, $routine, $pars) = @_;
	
	my $job_id = $self -> _new_job_id();
	
	$self -> {'routines'} -> {$job_id} = $routine;
	$self -> {'pars'} -> {$job_id} = $pars;
	
	return $job_id;
}


# -----------------------------------------------
sub run_jobs {
# -----------------------------------------------
	my ($self, $n) = @_;
	
	
	while (keys(%{$self -> {'routines'}})){
		
		my @job_ids = sort {$a <=> $b} keys(%{$self -> {'routines'}});
		
		foreach my $job_id (@job_ids){
						
			my $current_n = $self -> _update_jobs();
			
			if (!defined $n || $current_n  < $n){
					
				my $routine = $self -> {'routines'} -> {$job_id};
				my $pars = $self -> {'pars'} -> {$job_id};
				
				my $pid = fork();
						
				if ($pid){		
						
							
					# Parent
					delete $self -> {'routines'} -> {$job_id};
					delete $self -> {'pars'} -> {$job_id};
					$self -> {'pids'} -> {$pid} = $job_id;
				}
				elsif (defined $pid && $pid == 0){
						
					
					# Child
					my $time_start_child = Benchmark -> new;
					
					
					# Run job
					&{$routine}(@{$pars});
					
					
					print STDOUT "Running time for job $job_id: ".timestr(timediff(Benchmark -> new, $time_start_child))."\n";
					exit(0);		
				}
				else {
					die "Couldn't fork: $!\n";
				}
			}	
		}
	}
}


# -----------------------------------------------
sub wait {
# -----------------------------------------------
	my ($self) = @_;
	
	my @pids = keys(%{$self -> {'pids'}});
	
	foreach (@pids){
		waitpid($_, 0);
		
		push(@{$self -> {'finished_jobs'}}, $self -> {'pids'} -> {$_});
		delete($self -> {'pids'} -> {$_});
	}
}


# -----------------------------------------------
sub _update_jobs {
# -----------------------------------------------
	my ($self) = @_;
	
	my @pids = keys(%{$self -> {'pids'}});
	
	foreach (@pids){
		if (!kill(0 => $_)){
			
			waitpid($_, 0);
			
			push(@{$self -> {'finished_jobs'}}, $self -> {'pids'} -> {$_});
			delete($self -> {'pids'} -> {$_});	
		}
	}
	
	my $pids = keys(%{$self -> {'pids'}});
	
	return $pids;
}


# -----------------------------------------------
sub _new_job_id {
# -----------------------------------------------
	my ($self) = @_;

	my $job_increment = $self -> {'job_increment'};
	$job_increment++;
	$self -> {'job_increment'} = $job_increment;
	
	return $job_increment;
}


1;