#!/usr/bin/perl
#
# genesis.t
#
# Test script for GenesisFunc.pm
#
# Created 17th August 2017
# Matthew Gillman
# Queen Mary University of London
#
# Warning: if you change the content of test.stt.txt, test.config.txt or any other input to
# the tests then you need to update what the test expects to receive back from the function call.
# 
# Some GenesisFunc subroutines are to generate C++ files. For extra tests, these could have their
# MD5 sum checked to see that they have the correct content, given the input files supplied. md5sum
# can be used on Linux and certutil on Windows (NB earlier versions of certutil may not have had required options).
# NB it is possible the same file will have a different checksum on Linux and Windows due to the different
# line endings the two OS's employ.
# $^O gives the OS, e.g. "MSWin32" or "linux".

use strict;
use warnings;
use GenesisFunc;
use Test::More;


#
# We use %sources, a hash of hashes, to gather the info required from the STT.
# Outer hash: key = name of source class
# outer hash value = an inner hash with key = name of sink class,
#                    inner value = list (agestart, ageend, prob, agestart,ageend,prob...)
#
# Sinks will appear in the %allstates hash but not in %sources
#

# Keep track of sources only:
my %sources;
my $s = \%sources;
# Usage: $s->{a source}->{a sink) should be a ref to a list of transition triples.
# There can be more than one for a given source/sink pair, based on ages.

my @list_of_all_states = (); # A sorted list of names of all states (sources and sinks) in stt.txt
my $listref = \@list_of_all_states;

my $stt = "test.stt.txt"; # State transition table file
my $config = "test.config.txt"; # User-specified parameters file.
my $results = "test.results.csv"; # Output results file


print "\n\nCommencing genesis test suite.\n\n";

#is (&GenesisFunc::by_number(10,20), -1);
#my @res =  sort GenesisFunc::by_number(10,20);
#print "\nres = @res";


############### Testing parse_stt() #################

# Does it update $listref correctly, with the contents of test.stt.txt?

&parse_stt($stt, $s, $listref); # &GenesisFunc::parse_stt($stt, $s, $listref);

is ($listref->[0], "cin1", "Testing listref from parse_stt()");
is ($listref->[1], "normal", "Testing listref from parse_stt()");
is ($listref->[2], "occult", "Testing listref from parse_stt()");
is ($listref->[3], "symp", "Testing listref from parse_stt()");
is ($listref->[4], "treated", "Testing listref from parse_stt()");
is ($listref->[5], undef, "Testing listref from parse_stt()");
#is ($listref->[0], "treated", "Testing listref");

# Check the hash of hashes outer keys are all present and correct
my @outer_array = sort keys %$s;
is ($outer_array[0], "cin1", "Checking outer keys of hash of hashes (1)");
is ($outer_array[1], "normal", "Checking outer keys of hash of hashes (2)");
is ($outer_array[2], "occult", "Checking outer keys of hash of hashes (3)");
is ($outer_array[3], undef, "Checking outer keys of hash of hashes (4)");

# Check an inner hash's array is all present and correct
my $arrayref = $s->{"occult"}->{"symp"};
is ($arrayref->[0], 12, "testing array in hash of hashes (1)");
is ($arrayref->[1], 20, "testing array in hash of hashes (2)");
is ($arrayref->[2], 0.05, "testing array in hash of hashes (3)");
is ($arrayref->[3], 20, "testing array in hash of hashes (4)");
is ($arrayref->[4], 40, "testing array in hash of hashes (5)");
is ($arrayref->[5], 0.06, "testing array in hash of hashes (6)");
is ($arrayref->[6], undef, "testing array in hash of hashes (7)");



############## Testing generate_header() #########

# Check it does not alter the array sent to it
my @old = @list_of_all_states;

&generate_header($listref);

is (scalar @old, scalar @list_of_all_states, "Checking array same size - generate_header()");
my $length = scalar @old;
for (my $i = 0; $i < $length; $i++) {
    is ($old[$i], $list_of_all_states[$i], "Checking array content (index $i) unchanged - generate_header()");
}



############## Testing generate_impl() #########

# We send in the same array and again check it has not changed.
&generate_impl($s, $listref);

# NB this and the same code above should really be moved to a function to avoid code duplication.

is (scalar @old, scalar @list_of_all_states, "Checking array same size - generate_impl()");
$length = scalar @old;
for (my $i = 0; $i < $length; $i++) {
    is ($old[$i], $list_of_all_states[$i], "Checking array content (index $i) unchanged - generate_impl()");
}

# We also check the hash of hashes is not changed.
# TODO - put this and relevant testing code for parse_stt() into a function.


############# Testing check_transitions() ##################
# args: (1) reference to the array of triples (start age, end age, prob)
# for one source-sink pair, (2) the source state and (3) the sink state.

my @triples = qw /20 40 0.02 40 60 0.03 /;
my $triplesref = \@triples; 

# Check we get ok back when expected
is (&GenesisFunc::check_transitions($triplesref, "asource", "asink"), "ok",  "check_transitions()");

@triples = qw /40 60 0.03 20 40 0.02/;
is (&GenesisFunc::check_transitions($triplesref, "asource", "asink"), "ok",  "check_transitions()");

# Check we get failure when we send in insufficient data
@triples = qw / /;
is (&GenesisFunc::check_transitions($triplesref, "asource", "asink"), "Not enough data!",  "check_transitions()");

@triples = qw / 20 40 /;
is (&GenesisFunc::check_transitions($triplesref, "asource", "asink"), 
      "Not enough data!",  "check_transitions()");

# Check we get failure when data not a multiple of 3
@triples = qw / 20 40 0.2 50 /;
is (&GenesisFunc::check_transitions($triplesref, "asource", "asink"), 
      "Length of data not a multiple of 3!",  "check_transitions()");


# Check we get failure if prob is < 0 or > 1:
@triples = qw /20 40 0.2 40 60 -0.00000000001/;
is (&GenesisFunc::check_transitions($triplesref, "asource", "asink"), 
      "prob < 0 for a asource-asink pair transition",  "check_transitions()");

@triples = qw/20 40 0.2 40 60 1.00000000001/;
is (&GenesisFunc::check_transitions($triplesref, "asource", "asink"), 
      "prob > 1 for a asource-asink pair transition",  "check_transitions()");

# Check we get failure when same start age used in > 1 interval for source/sink pair transitions
@triples = qw /20 40 0.2 20 50 0.3/;
is (&GenesisFunc::check_transitions($triplesref, "asource", "asink"), 
      "same start age (20) used in > 1 interval for asource-asink pair transition",  "check_transitions()");

# Check we get failure when same end age used in > 1 interval for source/sink pair transitions
@triples = qw/20 30 0.2 25 30 0.1/;
is (&GenesisFunc::check_transitions($triplesref, "asource", "asink"), 
      "same end age (30) used in > 1 interval for asource-asink pair transition",  "check_transitions()");

# Check we get failure when age intervals overlap for same source/sink pair.
@triples = qw /20 40 0.2 30 50 0.3/;
is (&GenesisFunc::check_transitions($triplesref, "asource", "asink"), 
      "overlapping age ranges in asource-asink pair transition",  "check_transitions()");



############## Testing generate_main() #########
# &generate_main($config, $results);
# I think the only thing we can test at the moment is the output file ($results) contents.



done_testing();  

print "\n If any tests failed there should be a message here about it. If not, you're OK.\n";

__END__;




