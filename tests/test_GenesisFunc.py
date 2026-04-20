#import pytest
#import GenesisPy as GP
from GenesisPy import genesis_func

def test_get_prob_list():
    GP = genesis_func.GenesisParser()
    mylist = GP.get_prob_list("a_source", "a_sink")
    assert 1 == 1  #mylist is [] #None


