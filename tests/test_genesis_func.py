import pytest
from GenesisPy import genesis_func

# Assumes pytest is called from top-level directory.

def test_get_empty_prob_list():
    GP = genesis_func.GenesisParser()
    mylist = GP.get_prob_list("a_source", "a_sink")
    assert mylist is None


def test_missing_file():
    GP = genesis_func.GenesisParser()
    with pytest.raises(FileNotFoundError): # as err:
        GP.parse_stt("missing_file.txt")


def test_normal_stt_parse():
    GP = genesis_func.GenesisParser()
    test_dict = GP.parse_stt("tests/sample_stt.txt")
    outer_keys = sorted(test_dict.keys())
    assert outer_keys == ["cin1", "normal", "occult"]

