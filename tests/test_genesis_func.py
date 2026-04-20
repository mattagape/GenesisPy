import pytest
#import GenesisPy as GP
from GenesisPy import genesis_func

def test_get_empty_prob_list():
    GP = genesis_func.GenesisParser()
    mylist = GP.get_prob_list("a_source", "a_sink")
    #assert 1 == 1  #mylist is [] #None
    assert mylist is None


def test_missing_file():
    GP = genesis_func.GenesisParser()
    with pytest.raises(FileNotFoundError): # as err:
        GP.parse_stt("missing_file.txt")


def test_normal_stt_parse():
    

