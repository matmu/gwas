package Parallel::SystemFork;

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
	$self -> {'cmds'} = {};
	$self -> {'finished_jobs'} = [];
	
	bless($self, $class);
	
	$SIG{CHLD} = 'IGNORE';
	
	return($self);
}


# -----------------------------------------------
sub add_job {
# -----------------------------------------------	
	my ($self, $cmd) = @_;
	
	my $job_id = $self -> _new_job_id();
	
	$self -> {'cmds'} -> {$job_id} = $cmd;
	
	return $job_id;
}


# -----------------------------------------------
sub run_jobs {
# -----------------------------------------------
	my ($self, $n) = @_;
	
	
	while (keys(%{$self -> {'cmds'}})){
		
		my @job_ids = sort {$a <=> $b} keys(%{$self -> {'cmds'}});
		
		foreach my $job_id (@job_ids){
						
			my $current_n = $self -> _update_jobs();
			
			if (!defined $n || $current_n  < $n){
					
				my $cmd = $self -> {'cmds'} -> {$job_id};
				
				my $pid = fork();
						
				if ($pid){		
						
							
					# Parent
					delete $self -> {'cmds'} -> {$job_id};
					$self -> {'pids'} -> {$pid} = $job_id;
				}
				elsif (defined $pid && $pid == 0){
						
					
					# Child
					my $time_start_child = Benchmark -> new;
					
					
					# Run job
					system($cmd);
					
					
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
sub _kill {
# -----------------------------------------------
	my ($self, $pid) = @_;
	

	if (exists(${$self -> {'pids'}}{$pid})){
		kill('SIGTERM', $pid);
		waitpid($pid, 0);
		
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