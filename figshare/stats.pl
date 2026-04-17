#!/usr/bin/perl
#
# stats.pl
#
# Matthew Gillman, KCL, 16/04/2018
#
# This program will parse an output "results.csv" file from
# genesis and produce useful statistics about the transitions.
#
# ID,12,14,16,18,...
# 1,normal,normal,normal,cin1,...
# ...
use strict;
use warnings;

# Key = comma-separated position in line, starting at 0.
# Value = age (from header line) corresponding to that position.
my %ages;

# Outer hash: key = from state. Value = inner hash
# Inner hash: key = to state. Value = list of ages atthis to-from transition
my %hash;
my $href = \%hash;

my $infile = "results.csv";

# Open file for reading.
open (my $fh, "<", $infile) or die "\nCannot open $infile: $!\n";

# Extract ages from header and populate %ages.
my $header = <$fh>;
chomp($header);
my @items = split /,/, $header;
my $len = scalar @items;
#print "\n there are $len items\n"; 
my $ID = $items[0];
for (my $i = 1; $i < $len; $i++) {
    $ages{$i} = $items[$i];
}

# Extract ages of each From->To state transition
while (my $line = <$fh>) {

    @items = ();
    @items = split /,/, $line;
    $ID = $items[0];
    my $source = $items[1];

    my $sink;

    for (my $i = 2; $i < $len; $i++) {
	my $state = $items[$i];

	if ( $state ne $source ) {
	    $sink = $state;
	    my $age = $ages{$i};
	    my $arrayref = $href->{$source}->{$sink};
	    
	    # If array does not exist, create it
	    if ( ! defined($arrayref) ) {
		my @newarray = ();
		push (@newarray, $age);
		#my $arrayref = \@newarray;
		$href->{$source}->{$sink} = \@newarray;
	    }
	    # otherwise just add to it
	    else {
		push (@$arrayref, $age);
	    }

	    # Reset; the sink state is the new source state
	    $source = $sink;

	}
    }
}

close $fh;

# Output results 
print "\nSTATE TRANSITIONS SUMMARY - AGES";
print "\nFrom\tTo\tNum\tMean\tMedian\tQ1\tQ3\tQ3-Q1";
print "\n--------------------------------------------------------------";
my %outerhash = %$href;
my @outers = keys %outerhash;
my $outerlen = scalar @outers;

for (my $i = 0; $i < $outerlen; $i++) {
    my $source = $outers[$i];
    #print "$source\n";
    my $innerhashref = $outerhash{$source};
    my %innerhash = %$innerhashref;
    my @inners = keys %innerhash;
    my $innerlen = scalar @inners;

    if ( $source ne '' ) {
	for (my $j = 0; $j < $innerlen; $j++) {
	    my $sink = $inners[$j];
	    if ( $sink ne '' ) {

		my $arrayref = $href->{$source}->{$sink};
		if ( defined ($arrayref) ) {

		    my ($num, $me, $med, $q1, $q3) = get_stats($arrayref);
		    my $iqr = $q3 - $q1;
		    printf ("\n$source\t$sink\t$num\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f", $me, $med, $q1, $q3, $iqr );
		}
	    }
	}
    }
}

print "\n\n";


################################################
#
# sub get_stats()
#
# Takes in an array reference and provides useful
# statistics.
#
################################################
sub get_stats {

    my ($aref) = @_;
    my @nums = @$aref;
    my $len = scalar @nums;
    my @sorted = sort (@nums);
    my $sum = 0;
    for (my $i = 0; $i < $len; $i++) {
	###print $sorted[$i] . ",";
	$sum += $sorted[$i];
    }
    my $mean = $sum/$len;

    # Wikipedia entry for IQR
    # If the number of entries is an even number 2n, 
    # then the first quartile Q1 is defined as
    # first quartile Q1 = median of the n smallest entries
    # and the third quartile Q3 = median of the n largest entries[6]
    # 
    # If the number of entries is an odd number 2n+1,
    # then the first quartile Q1 is defined as
    # first quartile Q1 = median of the n smallest entries
    # and the third quartile Q3 = median of the n largest entries[6]
    #
    # The second quartile Q2 is the same as the ordinary median.[6]

    # testing
    #@sorted = (1,2,3,4,5,6,7,8,9,10);
    #$len = scalar(@sorted);

    my $median = find_median(@sorted);

    my $n;
    if ( $len%2 ) { # odd $len = 2*$n + 1
	$n = ($len-1)/2;
    }
    else { # even
	$n = $len/2;
    }

    my @smallest = ();
    for (my $i = 0; $i < $n; $i++) {
	push(@smallest, $sorted[$i]);
    }
    my $Q1 = find_median(@smallest);

    my @largest = ();
    for (my $i = $len-1; $i >= $len-$n; $i--) {
	push (@largest, $sorted[$i]);
    }
    @largest = reverse(@largest);
    my $Q3 = find_median(@largest);

    #print "\nresults = $median, $Q1, $Q3\n";
    #exit;

    return ($len, $mean, $median, $Q1, $Q3);

}

# Find median of a SORTED list
# i.e. sorted in ascending numerical order.
# Must sort before calling this
sub find_median {

    my (@sorted) = @_;
    my $len = scalar @sorted;

    # http://www.perlmonks.org/?node_id=474564
    my $median;
    if ( $len%2 ) { # odd
	$median = $sorted[int($len/2)];
    }
    else { # even
	$median = ($sorted[int($len/2)-1] + $sorted[int($len/2)])/2;
    }

    return $median;
}

# Example output
#
#STATE TRANSITIONS SUMMARY - AGES
#From    To      Num     Mean    Median  Q1      Q3      Q3-Q1
#--------------------------------------------------------------
#cin1    normal  2       23.00   23.00   18.00   28.00   10.00
#cin1    occult  5       28.80   28.00   22.00   36.00   14.00
#normal  cin1    7       19.43   18.00   16.00   20.00   4.00
#occult  symp    2       32.00   32.00   30.00   34.00   4.00
#occult  treated 3       42.00   46.00   32.00   48.00   16.00




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


