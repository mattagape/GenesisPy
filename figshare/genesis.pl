#!/usr/bin/perl
#
# genesis.pl
# Created 31st January 2017
# Matthew Gillman
# Queen Mary University of London
#

use strict;
use warnings;
use autodie;
use GenesisFunc;


################################################
#
# main
#
################################################

# Disable output buffering to screen:
select(STDERR);
$| = 1;
select(STDOUT);
$| = 1;

my $stt = "stt.txt"; # State transition table
my $config = "config.txt"; # User-specified parameters.
my $results = "results.csv"; # Results file.

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

eval {
&parse_stt($stt, $s, $listref); # &GenesisFunc::parse_stt($stt, $s, $listref);
&generate_header($listref);
&generate_impl($s, $listref);
&generate_main($config, $results);
};
die $@ if $@;
print "\n\nYou should be OK to compile and run things now.\n";

# To compile and run:
#
# On Apocrita:
# perl genesis.pl
# module load gcc/5.2.0
# g++ -std=c++11 simulation.cpp myclasses.cpp -o simulation
#
# or maybe:
# g++ -g3 -Wall -Wextra -Wstrict-overflow=5 -std=c++11 -ansi -pedantic -W
#     -Wconversion -Wshadow -Wcast-qual -Wwrite-strings -std=gnu++11
#     simulation.cpp myclasses.cpp -o simulation
#
# Then:
# ./simulation
#
# On Windows:
# cl /EHsc simulation.cpp myclasses.cpp
# simulation
