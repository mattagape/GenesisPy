# Use "pip install -e ." in top-level dir during development.

import re


class GenesisParser:
    """Contains methods to be used by Genesis. Adapted from GenesisFunc.pl."""

    def __init__(self):

        """Dictionary of state transitions """
        self.transition_dict = {}

    def parse_stt(self, stt_file: str) -> dict:
        """Parse state transition table file and update data structures.
        
        Example data line:
        occult symp 20 40 0.06
        which means "The probability of a transition from the 'occult' state to the
        'symp' state, for ages >= 20 and < 40, is 0.06."
        """

        # Open the file and read it in a line at a time:
        with open(stt_file, encoding="utf-8") as input:

            for line in input:            
                # Skip over comment lines (starting with '#').
                if (re.match('#', line)):
                    print (line, end='')
                    continue
                
                # Remove any '\n' or '\r' characters from line.
                line = line.strip()

                # Skip over any empty lines.

                # Parse a data line into a tuple, e.g.:
                # ('occult', 'symp', '20', '40', '0.06')
                tup = tuple(line.split())
                if ( len(tup) != 5 ):
                    # TODO raise custom error
                    print("Parsing error on line ___")
                    return None
                transition_prob = tuple(tup[2:])
                source = tup[0]
                sink = tup[1]
                prob_list = self.get_prob_list(source, sink)
                #self.transition_dict

            print(f"Parsing of {stt_file} complete.")


    def get_prob_list(self, source: str, sink: str) -> list:
        """Get the relevant list of state transitions for this source/sink pair.
           
            A source state may well have multiple sink states.
            "Outer" key is the name of a source state. Value = "inner" dictionary
            Inner dict key is the name of a sink state, with value = 
            a list of age-based triples
            (Each triple with start age, stop age, prob)        
        """
        outer_dict = self.transition_dict
        if ( outer_dict == {} ):
            print("ERROR: dictionary is empty. Did you parse the stt?")
            return None

        if source not in outer_dict:
            outer_dict[source] = dict()
        inner_dict = outer_dict[source]
        if sink not in inner_dict:
            inner_dict[sink] = list()
        return outer_dict[source][sink]


# Sanity check
if __name__ == "__main__":
    GP = GenesisParser()
    GP.parse_stt("../../figshare/stt.txt")
