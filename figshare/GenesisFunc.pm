#!/usr/bin/perl
#
# GenesisFunc.pm
# Created 31st January 2017
# Matthew Gillman
# Queen Mary University of London
#
# Based on http://www.perlmonks.org/?node=Simple%20Module%20Tutorial
#
package GenesisFunc;

use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT);
use File::Sync qw(fsync sync);

$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = qw/parse_stt generate_header generate_impl generate_main/;


# Given a STT (state transition table) file like this:
# occult symp 12 20 0.05
# occult symp 20 40 0.06
# occult treated 12 80 0.07
# normal cin1 12 80 0.01
# cin1 occult 12 80 0.005
# we want to create C++ classes to represent states occult, symp, treated, normal & cin1
# First line means "prob of transitioning from occult to symp is 0.05 between ages 12 and 20"
#
# You do not have to have all the (e.g.) occult source classes/states together in the STT file.
# They can be scattered about and intermixed amongst the others.
#
# Should end up with C++ classes like this:
#
# *** In header file: ***
#
# class occult : public State {
#	public:
#	occult() { cout << "occult ctor" << endl; }
#	~occult() {cout << "occult dtor" << endl;}
#	void goNext(Machine* m); 
#};
#
# *** In impl file: ***
#
# void occult::goNext(Machine* m) {
#	if (m->age >= 12 && m->age < 20) {
#		if (m->prob >= 0 && m->prob < 0.05) {
#			m->setNext(new symp());
#			delete this;
#			return;
#       	}	
#		if (m->prob >= 0.05 && m->prob < 0.05 + 0.07) {
#			m->setNext(new treated());
#			delete this;
#			return;			
#		}		
#	}
#	if (m->age >= 20 && m->age < 40) {
#		if (m->prob >= 0 && m->prob < 0.06) {
#			m->setNext(new symp());
#			delete this;
#			return;
#		}
#		if (m->prob >= 0.06 && m->prob < 0.06 + 0.07) {
#			m->setNext(new treated());
#				delete this;
#				return;
#		}		
#	}
#	if (m->age >=40 && m->age < 80) {
#		if ( m->prob >= 0 && m->prob < 0.07 ) {
#			m->setNext(new treated());
#			delete this;
#			return;
#		}
#	}
#	// Else we are still in occult state.
#	cout << "Still in occult state." << endl;
#	return;
#}
#
# etc.


################################################
#
# sub by_number()
#
# Utility function to sort values (e.g. hash keys)
# by numerical value rather than by ASCII value.
#
# Obtained from page 215 of "Learning Perl" (3rd ed.),
# Randal L. Schwartz & Tom Phoenix, O'Reilly: 
# Sebastopol (2001)
#
################################################
sub by_number {
    if ($a < $b) { -1 } elsif ($a > $b) {1} else {0}
}


################################################
#
# sub parse_stt($sttfile, $hashref, $alistref)
#
# Parse state transition table file and update data structures.
#
# ARGS:
# $sttfile - name of state transition table file.
# $hashref - reference to hash having key = name of source class,
#            value = an inner hash with key = name of sink class, 
#                                       value = list of transition (start age, end age, probability) triples
# $listref - reference to a list of ALL states in the file (i.e. both sources and sinks)
#
# Each line should have a source state, sink state, age range for that transition,
# and probability of that transition. Example:
#
# occult symp 20 40 0.06
#
# Note that, for a given source, there can be multiple sinks,
# each based on a different age range and/or prob.
#
# NB we may have a sink (e.g. death) from which no transitions possible. This would only be listed
# in 2nd column of STT file, but will need a class definition anyway (albeit with no transitions out).
#
################################################
sub parse_stt {
    my ($sttfile, $hashref, $alistref) = @_;

    # A hash of ALL states encountered, both sources and sinks.
    my %allstates; # key = state name, value = count

    open my $in, '<', $sttfile or die "Could not open file $sttfile: $!\n";

    while (my $line = <$in>) {
	next if ($line=~/#/);
	#print $line;
	
	chomp($line);
	
	# We don't need to strip off Windows metacharacters as we are splitting on whitespace.
	my @parts = split(/ /, $line);
	if ($#parts < 4) {
                die "\nError: not enough parts in line of stt.txt ($line)\n";
        }
	my $source = $parts[0];
	my $sink = $parts[1];
	my $startage = $parts[2];
	my $endage = $parts[3];
	my $prob = $parts[4];

#	print "\nLINE:($line), prob = ($prob)\n";

#	chomp($prob);

#	if ( !defined($prob) ) {
#	if ( $prob eq undef || $prob == undef || $prob eq '' || $prob == "" || ! $prob || length($prob) == 0) {
#		die "\nError: not enough parts in line of stt.txt ($line)\n";
#	}
#	if ( $prob eq '') { print "\nEMPTY\n";}
#	else { print "\nNOT empty\n";} 

	## error check
	#if ($prob == undef) {
	#	die "\nError: not enough parts in line of stt.txt ($line)\n";
	#}		

	#print "\nDEBUG: endage is $endage\n";
	
	#
	# Initial sanity checks.
	#
	if ( $startage < 0 ) { 
	    die "\nERROR: you have a start age for a $source to $sink transition of $startage (<0) !\n"; 
	}
	if ( $startage > $endage ) { 
	    die "\nERROR: for a $source to $sink transition startage > endage ($startage > $endage) !\n"; 
	}
	
	# Update the record of ALL states.
	$allstates{$source}++;
	$allstates{$sink}++;

	# Now push data onto the array for the relevant inner hash (sink)
	my $arrayref = $hashref->{$source}->{$sink};
	
	if ( not defined $arrayref ) {
	    my @empty = ();
	    $arrayref = \@empty;
	    $hashref->{$source}->{$sink} = $arrayref;
	}
	
	push (@$arrayref, $startage, $endage, $prob);
		
    }
    close $in;

    my @list_of_all_my_states = sort keys(%allstates);

    push (@$alistref, @list_of_all_my_states);

}


################################################
#
# sub generate_header($alistref)
#
# ARGS:
# $alistref - reference to the list of all states in stt.txt
#
# AUTOGENERATION OF HEADER FILE
#
################################################
sub generate_header() {

    my ($alistref) = @_;

    # Create C++ classes.
    # First we need to create the myclasses.h file - declares all classes (sources and sinks)
    open my $header, '>', "myclasses.h" or die "Could not open output header file: $!\n";
	
    my $text = <<"END_TEXT";
// myclasses.h
#ifndef _MYCLASSES_H
#define _MYCLASSES_H
	
#include "state.h"
	
END_TEXT

    print $header $text;
	
    my $listlen = scalar @$alistref;

    # Forward declare each class.
    for (my $i = 0; $i < $listlen; $i++ ) {
	my $c = $alistref->[$i];
	$text = <<"END_TEXT";
	class $c;
END_TEXT
    print $header $text;
    }

    print $header "\n";
    
    # Now give definition of each class (except for goNext() function). Example:
    # class normal : public State {
    #	public:
    #	normal() { cout << "normal ctor" << endl; }
    #	~normal() { cout << "normal dtor" << endl; }
    #	void goNext(Machine* m); // defined elsewhere
    #};
    for (my $i = 0; $i < $listlen; $i++ ) {
	my $c = $alistref->[$i];
	$text = <<"END_TEXT";

class $c : public State {
public:
    $c() { std::cout << "Entering $c state" << std::endl; }
    ~$c() { /*cout << "$c dtor" << endl;*/ }
    void goNext(Machine* m);
};
	
END_TEXT

        print $header $text;

    }
	
    $text = <<"END_TEXT";
	
#endif // _MYCLASSES_H

END_TEXT
    print $header $text;
	
    close $header;
	
} # End sub generate_header()


################################################
#
# sub generate_impl($hashref, $alistref)
#
# AUTOGENERATION OF IMPLEMENTATION FILE
#
# ARGS:
# $hashref - reference to the hash of hashes of transition triples.
# $alistref - reference to the list of all states in stt.txt
#
################################################
sub generate_impl() {
	
    my ($hashref, $alistref) = @_;

	$| = 1;
	
    open my $impl, '>', "myclasses.cpp" or die "Could not open output file myclasses.cpp: $!\n";

#	binmode $impl;

    my $text = <<"END_TEXT";
// myclasses.cpp
#include "state.h"
#include "myclasses.h"

Machine::Machine(State* init, double myage, double initprob, std::string start )
: current(init), age(myage), prob(initprob) {
    statename = new std::string(start);
}	
	
END_TEXT
    #print $impl $text or die "Could not print impl text: $!\n";
    syswrite $impl, $text;
    ## Force contents to be flushed to disk
    #close($impl);

    #open $impl, '>>', "myclasses.cpp" or die "Could not append to output file myclasses.cpp: $!\n";


    #fsync($impl);
    #print $impl "\n";
	
    # Now we need to define the goNext() functions for all our classes.
    # This will vary based on whether they are a final sink or not.
    # Forward declare each class.
    my $listlen = scalar @$alistref;

    #print "\llistlen is $listlen\n";


    for (my $i = 0; $i < $listlen; $i++ ) {
	my $c = $alistref->[$i];
	print "Processing class $c;\n";

	$text = <<"END_TEXTA";
void $c :: goNext(Machine* m) {
END_TEXTA
        #print $impl $text;
	#sync();
	syswrite $impl, $text or die "Error: can't syswrite: $!\n";	

	syswrite $impl, "//test\n";
	#close($impl);


        # If this state is a final sink, the implementation is easy:
        if ( ! exists $hashref->{$c} ) {
	    $text = <<"END_TEXT";
	    std::cout << "In a final state ($c).\\n";	
END_TEXT
            #print $impl $text;
	#		sync();	
		syswrite $impl, $text;
				
	    print "** Source $c has no sinks!\n";
	}
	
        else { # Source needs more processing!
				
	    # Iterate over the inner hash for this source class.
	    # Inner hash key is a sink class and value is an array of (startage, stopage, prob) triples.
	    # For example above, source occult should have sinks symp and treated.
	    my $innerhashref = $hashref->{$c};
	    my @sinks_for_this_source = sort keys (%$innerhashref);
	    my $numsinks = scalar (@sinks_for_this_source);
		
	    print "Source $c has $numsinks sinks!\n";
		
	    my %ages = ();
	    my @all_age_boundaries = ();
		
	    #
	    # Iterate over sinks - extract age boundary information from all sinks.
	    #
	    for (my $j = 0; $j < $numsinks; $j++) {
		my $sink = $sinks_for_this_source[$j];
		print "**Source $c has a sink $sink\n";
		my $triplesref = $innerhashref->{$sink};
			
		if (not defined $triplesref) {
		    die "ERROR: triplesref not defined!\n";
		}
			
		my $ctmsg = &check_transitions($triplesref, $c, $sink);
		if ($ctmsg ne "ok") {
		    die "\ncheck_transitions() call failed; $ctmsg \n";
		}
			
		my @triples = @$triplesref;
		my $length = @triples;
		#print "length is $length\n";
		for (my $k = 0; $k < $length - 2; $k = $k + 3) {
		    # can't just use a list as same age may be duplicated over more than one sink
		    #push (@all_age_boundaries, $triples[$k]);
		    #push (@all_age_boundaries, $triples[$k+1]);	
		    $ages{$triples[$k]}++;
		    $ages{$triples[$k+1]}++;
		}		
	    }
		
	    @all_age_boundaries = sort by_number keys %ages;
	    #print "DEBUG: all age boundaries list is now: "; 
            # e.g. 12,20,40,80 ->ranges 12-20,20-40,40-80 each need an if statement
	    #print @all_age_boundaries;
	    #print "\n";
		
	    #
	    # Iterate over all age intervals found.
	    #
	    my $aablen = @all_age_boundaries;
	    for (my $j = 0; $j < $aablen - 1; $j++) {
		
		my $interval_start = $all_age_boundaries[$j];  # e.g. 12
		my $interval_end = $all_age_boundaries[$j+1];  # e.g. 20
		my $cumprob = 0;
				
		$text = <<"END_TEXT";
	if (m->age >= $interval_start && m->age < $interval_end) {	
END_TEXT
                #print $impl $text;
		#sync();	
		syswrite $impl, $text;
			
                # Iterate over all sinks for this source $c and pull out age range and
                # prob for each which fall within this interval.
                for (my $k = 0; $k < $numsinks; $k++) {
				
		    my $sink = $sinks_for_this_source[$k];
				
		    my $triplesref = $innerhashref->{$sink};
		    my @triples = @$triplesref;
		    my $length = scalar @triples;
		    for (my $z = 0; $z < $length-2; $z = $z + 3) {
			my $age1 = $triples[$z];
			my $age2 = $triples[$z + 1];
			my $prob = $triples[$z + 2];
					
			my $start = undef;
			my $stop = undef;
					
			# Do not process these ages if the age-pair from the sink's list
			# does not overlap with the interval being considered.
			if ( $age1 >= $interval_end || $age2 < $interval_start ) {
			    next; # Jump out of this loop.
			}
					
			# OK it overlaps - find start and stop age points to use.
			if ($age1 >= $interval_start) {
			    $start = $age1;
			}
			else {
			    $start = $interval_start;
			}				
			if ($age2 < $interval_end) {
			    $stop = $age2;
			}
			else {
			    $stop = $interval_end;
			}
					
			# Skip over trivial intervals
			next if ($start == $stop);
					
			# Once we have found the overlapping ages for this interval we can stop the loop as 
			# we won't (shouldn't) find any more for this interval (for this sink) TODO
					
					
			my $startprob = $cumprob;
			my $endprob = $cumprob + $prob;
			$cumprob = $endprob;
					
			print "=== Source: $c, sink: $sink, start: $start, stop: $stop, prob: $prob ($startprob, $endprob)\n";
						
			### Error check ###
			#if ($cumprob > 1) {
			#	print "\n\nERROR: cumulative probability > 1 in a transition from source state $c.";
			#	print "(age range: $interval_start to $interval_end)\n";
			#	die;
			#}
			
			# Example:
			# === Source: occult, sink: symp, start: 12, stop: 20, prob: 0.05 (0, 0.05)
			# === Source: occult, sink: treated, start: 12, stop: 20, prob: 0.07 (0.05, 0.12)
			# === Source: occult, sink: symp, start: 20, stop: 40, prob: 0.06 (0, 0.06)
			# === Source: occult, sink: treated, start: 20, stop: 40, prob: 0.07 (0.06, 0.13)
			# === Source: occult, sink: treated, start: 40, stop: 80, prob: 0.07 (0, 0.07)
			
			$text = <<"END_TEXT";
		   if (m->prob >= $startprob && m->prob < $endprob) {
		       m->setNextStateName("$sink");
		       m->setNext(new $sink());
		       delete this;
		       return;
		   }	
END_TEXT
                        #print $impl $text;
			#sync();		
			syswrite $impl, $text;
				
			### Error check 
                        ### Moved here so faulty prob will be written out in myclasses.cpp file for user to see.
			if ($cumprob > 1) {
			    print "\n\nERROR: cumulative probability > 1 in a transition from source state $c.";
			    print "(age range: $interval_start to $interval_end)\n";
			    die;
			}
						
		    } # End of for loop ($z, iterating over @triples for this sink.)
			
		} # End of for loop ($k, iterating over sinks for this source).
	
                $text = <<"END_TEXT";
	} // End if (age in interval)	
END_TEXT
                #print $impl $text;
		#sync();
		syswrite $impl, $text;
			
	    } # End of for-loop ($j, iterating over @all_age_boundaries)
			
	    $text = <<"END_TEXT";
			
	std::cout << "Still in $c state." << std::endl;
	return;	
	
END_TEXT
             #print $impl $text;
		#sync();
		syswrite $impl, $text;
		
	} # End else (sink is not a final state).
		
        $text = <<"END_TEXT";
} // End of goNext() for class $c.


END_TEXT
        #print $impl $text;
	#sync();
	syswrite $impl, $text;
		
    } # End (for)

    close $impl;
	
} # End sub generate_impl()


#####################################################################
#
# sub check_transitions()
#
# INPUT: (1) reference to the array of triples (start age, end age, prob)
# for one source-sink pair, (2) the source state and (3) the sink state.
#
# Checks there are no overlapping transitions for the same source/sink pair.
# e.g. this STT would give an error:
# ======================
# occult symp 12 25 0.01
# occult symp 40 60 0.05
# occult symp 20 40 0.03
#=======================
# because for the transition from occult to symp, what probability should
# apply if (say) age is 23? The age ranges overlap.
#
# Returns "ok" on success or an informative error string otherwise.
#
#####################################################################
sub check_transitions() {

    my ($ref, $mysource, $mysink) = @_;
    my @data = @$ref;
    my $datalen = scalar @data;

    if ( $datalen < 3 ) {
	return "Not enough data!";
    }

    if ( $datalen%3 != 0 ) {
	return "Length of data not a multiple of 3!";
    }

    my %starts = (); # Key = start of age range. Value = its end.
	
    # @data is an array of triples.
    for (my $index = 0; $index < $datalen - 2; $index += 3) {
		
	my $key = $data[$index];
	my $value = $data[$index + 1];
	if (exists $starts{$key}) {
	    return "same start age ($key) used in > 1 interval for $mysource-$mysink pair transition";
	}
	$starts{$key} = $value;

	# Check porbability is valid
	my $prob = $data[$index + 2];
	if ($prob < 0) {
	    return "prob < 0 for a $mysource-$mysink pair transition";
	}
	if ($prob > 1) {
	    return "prob > 1 for a $mysource-$mysink pair transition";
	}
    }

    # We also check that the END ages are not duplicated:
    my @ends = values(%starts);
    my %endhash = ();
    my $endvalslen = @ends;
    for (my $valindex = 0; $valindex < $endvalslen; $valindex++) {
	my $val = $ends[$valindex];
	if (exists $endhash{$val}) {
	    return "same end age ($val) used in > 1 interval for $mysource-$mysink pair transition";
	}
	$endhash{$ends[$valindex]}++;
    }

    # Finally, check that the age intervals do not overlap for this source-sink pair:
    my @sortedkeys = sort by_number keys %starts;
    my $len = scalar @sortedkeys; # should be same as $endvalslen.
    my @allintervals = ();
    for (my $index = 0; $index < $len; $index++) {
	my $k = $sortedkeys[$index];
	my $v = $starts{$k};
	push (@allintervals, $k, $v);
    }
	
    # We should find that @allintervals is always increasing in its values
    # as we iterate through it. If not this means there are overlapping ages.
    $len = @allintervals;
    for (my $index = 1; $index < $len - 1; $index+=2) {
	my $v1 = $allintervals[$index];       # A value = end of an age interval.
	my $v2 = $allintervals[$index + 1];   # A key = start of next age interval.
	if ($v1 > $v2) {
	    return "overlapping age ranges in $mysource-$mysink pair transition";
	}
    }

    return "ok";

} # End sub check_transitions().



#####################################################################
#
# sub generate_main($configfile, $resultsfile)
#
# Parse the config file for the required parameters, then create
# the file simulation.cpp based on those parameters.
#
# ARGS:
# $configfile - path to configuration file (e.g. ./config.txt)
# $resultsfile - path to results file (e.g. ./results.csv)
#
#####################################################################
sub generate_main {

    my ($configfile, $resultsfile) = @_;

    # Should the C++ program use the system clock to generate a seed for
    # the random number generator?	
    my $use_system_clock = 0;
    my $specialstring = "USE_SYSTEM_CLOCK";
	
	
    # Default parameter values (can override in config.txt):
    my $seedstring = "this is another test";
    my $startage = 12; # time units - these 
    my $stopage = 80;  # don't have to
    my $interval = 1;  # be in years.
    my $initialstate = "normal"; # Must be a state in the stt.txt file.
    my $number = 1;
	
	
    # Params for uniform distribution.
    # Eventually it might be nice to have the option of choosing which probability distribution
    # for the random number generator e.g. gaussian.
    # NB 0..1 is the range of probabilities so I don't know why anyone would want to change these.
    my $start_dist_range = "0.0";
    my $end_dist_range = "1.0";
	
    my %configparams = ();
	
    # Populate %configparams with default values. These can be overridden in config file.
    # We could use no strict 'refs' and use dynamic variable names as per
    # http://stackoverflow.com/questions/17434333/using-a-dynamically-generated-variable-name-in-perls-strict-mode
    # or ${$foo} or $$foo as per
    # http://www.justskins.com/forums/dynamically-substituting-variable-name-54801.html
    # instead if we wanted, but this is safer.
    $configparams{"seedstring"} = $seedstring;
    $configparams{"startage"} = $startage;
    $configparams{"stopage"} = $stopage;
    $configparams{"interval"} = $interval;
    $configparams{"initialstate"} = $initialstate;
    $configparams{"number"} = $number;
	
    #
    # Parse the config file
    #
    # Example file:
    # startage:12
    # stopage:80
    # seedstring:USE_SYSTEM_CLOCK
    # Last entry above is a special case.
	
    my $jumper = 0;
    open my $in, '<', $configfile or $jumper = 1;
    if ($jumper) {
	warn "\nCould not open config file $configfile: $!\nUsing default parameters instead...\n";
	goto JUMP;
    }
    while (my $line = <$in>) {
	next if ($line=~/#/);
	chomp ($line); # remove newline
	# remove Windows ^M from end of line using Input Record Separator:
	my $temp = $/; $/ = "\r\n"; chomp($line); $/ = $temp;
	my @parts = split(/:/, $line);
	if ( scalar (@parts) != 2 ) {
		die "\nError in $configfile; line is ($line)\n";
	}
	my $param_name = $parts[0];
	#chop($parts[1]); # This will remove Windows metacharacters but I guess it's platform-specific (could remove last char) so best avoided.
	my $param_value = $parts[1];
	$configparams{$param_name} = $param_value;
    }
    close $in;
	
	
  JUMP:
    $seedstring = $configparams{"seedstring"};
    $startage = $configparams{"startage"};
    $stopage = $configparams{"stopage"};
    $interval = $configparams{"interval"};
    $initialstate = $configparams{"initialstate"};
    $number = $configparams{"number"};
	
    # The seed string is a special case.
    # Use =~ as eq may not work if there is a trailing newline character
    # (a problem on Windows despite chomp() above. What about Linux?).
    if ( $seedstring eq $specialstring ) {
	$use_system_clock = 1;
	print "\nusing system clock\n";
    }
	
    print "\n\n***** I WILL USE THESE PARAMETERS: *****\n";
    my @paramkeys = sort keys (%configparams);
    for (my $ii = 0; $ii < @paramkeys; $ii++) {
	my $kk = $paramkeys[$ii];
	my $vv = $configparams{$kk};
	print "* $kk : $vv *\n";	
    }
	
	
    open my $sim, '>', "simulation.cpp" or die "Could not open output file simulation.cpp: $!\n";
	
    my $text = <<"END_TEXT";
// simulation.cpp
#include "state.h"
#include "myclasses.h"
#include <random>
#include <fstream>
#include <iostream>
#include <chrono> // Use this if you wish to generate the seed from system clock.
////using namespace std;

// NB we do not have actions. They maybe could be incorporated
// into additional states? (e.g. treated)
// For screening etc you could just change the transition probs
// in the STT.

// Client code.
// Although if it is all autogenerated it may not matter.
// Unless user wishes to tweak the client code.
int main(int argc, char** argv) {
	
	std::cout << "Starting simulation..." << std::endl;
	
	// Decide initial parameters: These will be set in the Perl script (or a config file)
	//State* ss = new $initialstate(); // user must decide which state to start with.
	double startage = $startage; // user must decide this
	double finalage = $stopage; // ditto
	double interval = $interval; // ditto again
	// plus seed e.g. a fixed string or from the clock.
	
	// Using a uniform distribution and Mersenne Twister to start with.
	std::uniform_real_distribution<double> distribution($start_dist_range, $end_dist_range);
END_TEXT
	
    print $sim $text;
	
	
	if ($use_system_clock) {
	    $text = <<"END_TEXT";
		
	// Using system clock to generate a seed:
	unsigned seed1 = std::chrono::system_clock::now().time_since_epoch().count();
END_TEXT
	}
	else {
	    $text = <<"END_TEXT";
	
	// Using user-specified fixed seed:	
	std::string str = "$seedstring";
	std::seed_seq seed1 (str.begin(),str.end());
END_TEXT
	}

	print $sim $text;
	
	
	
$text = <<"END_TEXT";
	
	std::mt19937 generator (seed1); 
	
	double startprob = distribution(generator); 
	std::cout << "Initial age: $startage\\n"
		<< "Initial class: $initialstate\\n"
		<< "Initial prob: " << startprob << std::endl;
	
	
	// Generate header of output csv file.
	std::string mystr = "$resultsfile";
	std::ofstream res(mystr);
	
	res << "ID,";
	for (double x = startage /*+ interval*/ ; x <= finalage; x += interval) {
		res << x << ",";
	}
	res << std::endl;
		
	std::string startstate = "$initialstate";
		
	for (unsigned long int i = 1; i <= $number; i++) {
		
		startprob = distribution(generator); 		
		std::cout << "\\nInitial prob is " << startprob << std::endl;
		State* ss = new $initialstate(); // user must decide which state to start with.
		Machine* m = new Machine(ss, startage, startprob, startstate);
		
		res << i << ",$initialstate,";
		
		for (double x = startage + interval ; x <= finalage; x += interval) {

			m->age = x;
			ss = m->current;
					
			m->prob = distribution(generator);
			std::cout << m->age << "\\t" << m->prob << "\\t"; // << std::endl;
			ss->goNext(m);
			
			res << m->statename->c_str() << ",";

		}
		

                // We need to do this if state switched immediately prior
		// to leaving the above loop.
		ss = m->current;
		
		delete m;
		delete ss;
				
		res << std::endl;

	}		
	
	res.close();
	
	return 0;

}
END_TEXT
	
	print $sim $text;
	
	close $sim;

}


1;
