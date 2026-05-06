# Use "pip install -e ." in top-level dir during development.

import re


class GenesisParser:
    """Contains methods to be used by Genesis. Adapted from GenesisFunc.pm."""

    def __init__(self):

        """Dictionary of state transitions 
        
        Example usage:
        
        transition_dict["occult"]["symp"] =  [("12", "20", "0.05"), ("20", "40", "0.06")]

        i.e., 
        transition_dict[a_source][one_of_its_sinks] = list of tuples of (start, end, prob)
        """
        self.transition_dict = {}

        self.all_states = {}

    def parse_stt(self, stt_file: str) -> dict:
        """Parse state transition table file and update data structures.
        
        Example data line:
        occult symp 20 40 0.06
        which means "The probability of a transition from the 'occult' state to the
        'symp' state, for ages >= 20 and < 40, is 0.06."
        """

        # Open the file and read it in a line at a time:
        with open(stt_file, encoding="utf-8") as input:

            line_num = 0

            for line in input: 

                line_num += 1

                # Skip over comment lines (starting with '#').
                if (re.match('#', line)):
                    # print (line, end='')
                    continue
                
                # Remove any '\n' or '\r' characters from line.
                line = line.strip()
                #print(line)

                # Skip over any empty lines.
                if (line == ""):
                    #print ("skipped empty line!")
                    continue

                # Parse a data line into a tuple, e.g.:
                # ('occult', 'symp', '20', '40', '0.06')
                tup = tuple(line.split())
                if ( len(tup) != 5 ):
                    # TODO raise custom error
                    print(f"Parsing error on line {line_num}.")
                    return None
                transition_prob_tuple = tuple(tup[2:])
                if (self.bad_tuple(transition_prob_tuple)):
                    raise SystemExit
                source = tup[0]
                sink = tup[1]
                prob_list = self.get_prob_list(source, sink)
                prob_list.append(transition_prob_tuple)

                # Update our dict of ALL states:
                if source not in self.all_states:
                    self.all_states[source] = 0
                if sink not in self.all_states:
                    self.all_states[sink] = 0
                # self.all_states[source] += 1
                # self.all_states[sink] += 1

            print(f"Parsing of {stt_file} complete.")
            return self.transition_dict


    def bad_tuple(self, tup: tuple) -> bool:
        """Returns True if error in tuple, tup.

        Tuple contains 3 strings, e.g. ("20", "40", "0.05")
        where the start age of this transition would be 20, the 
        stop age (just under) 40, and probability of 0.05.
        
        Reporting the line number would be helpful TODO 
        """
        if ( tup is None ):
            print ("Null tuple!")
            return True
        start = tup[0]
        end = tup[1]
        start_age = float(start)
        end_age = float(end)
        if ( start_age < 0 ):
            print("Error: start age < 0!!")
            return True
        if ( start_age > end_age ):
            print("Error: start age > end age!!")
            return True


    def get_prob_list(self, source: str, sink: str) -> list:
        """Get the relevant list of state transition tuples for this source/sink pair.
           
            A source state may well have multiple sink states.
            "Outer" key is the name of a source state. Value = "inner" dictionary
            Inner dict key is the name of a sink state, with value = 
                a list of age-based triples
            (Each triple with start age, stop age, prob)        
        """
        #import pdb;pdb.set_trace()

        outer_dict = self.transition_dict
        
        # The dict will be empty at first, so this next bit is wrong
        #if ( outer_dict == {} ):
        #    print("ERROR: dictionary is empty. Did you parse the stt?")
        #    return None
        
        if source not in outer_dict:
            outer_dict[source] = dict()
        inner_dict = outer_dict[source]
        if sink not in inner_dict:
            inner_dict[sink] = list()

        return outer_dict[source][sink]


    def check_transitions(self):
        """Check there are no overlapping or duplicate age states, etc."""
        pass

# Still need functions to : 
#
# - check_transitions() no overlapping age ranges, > 1 prob triple of 
#       same age range for same state source-sink pair
#
# Put these 3 in "writer" class:
# - generate C++ header "myclasses.h"
# - generate_impl "myclasses.cpp"
# - generate_main() - parse config and generate simulation.cpp 
#
# Also need "invoker" script:
# python genesis.py --stt "../../mystt.txt" --config "myconfig.txt" --outdir "./out/cpp"

# Sanity check. Call from same directory this file is in.
if __name__ == "__main__":
    GP = GenesisParser()
    GP.parse_stt("../../figshare/stt.txt")
