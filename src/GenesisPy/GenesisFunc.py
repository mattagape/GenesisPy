import re


class GenesisFunc:
    """Contains methods to be used by Genesis. Adapted from GenesisFunc.pl."""

    def parse_stt(self, stt_file: str):
        """Parse state transition table file and update data structures."""

        # Open the file and read it in a line at a time:
        with open(stt_file, encoding="utf-8") as input:

            for line in input:            
                # Skip over comment lines (starting with '#').
                if (re.match('#', line)):
                    print (line, end='')
                    continue
            print(f"Parsing of {stt_file} complete.")




# Sanity check
if __name__ == "__main__":
    GF = GenesisFunc()
    GF.parse_stt("../../figshare/stt.txt")
