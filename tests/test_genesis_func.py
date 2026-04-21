import pytest
from GenesisPy import genesis_func

# Assumes pytest is called from top-level directory.

def test_get_empty_prob_list():
    GP = genesis_func.GenesisParser()
    mylist = GP.get_prob_list("a_source", "a_sink")
    assert mylist == [] # As there won't be a list for this transition.


def test_missing_file():
    GP = genesis_func.GenesisParser()
    with pytest.raises(FileNotFoundError):
        GP.parse_stt("tests/missing_file.txt")


def test_normal_stt_parse():
    GP = genesis_func.GenesisParser()
    test_dict = GP.parse_stt("tests/sample_stt.txt")
    outer_keys = sorted(test_dict.keys())
    assert outer_keys == ["cin1", "normal", "occult"]

    # Each list should have one tuple only:
    assert test_dict["cin1"]["occult"] == [("12", "80", "0.3")]
    assert test_dict["normal"]["cin1"] == [("12", "80", "0.2")]
    assert test_dict["occult"]["treated"] == [("12", "80", "0.07")]

    # We expect a list of 2 tuples next
    my_list = test_dict["occult"]["symp"]
    assert len(my_list) == 2
    possibility_1 = [("12", "20", "0.05"), ("20", "40", "0.06")]
    possibility_2 = [("20", "40", "0.06"), ("12", "20", "0.05")]
    assert my_list == (possibility_1 or possibility_2)


def test_empty_file():
    GP = genesis_func.GenesisParser()
    mydict = GP.parse_stt("tests/empty_file.txt")
    assert mydict == {}
    mylist = GP.get_prob_list("", "")
    assert mylist == []

