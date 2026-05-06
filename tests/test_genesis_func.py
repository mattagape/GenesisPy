import pytest
from GenesisPy import genesis_func

# Assumes pytest is called from top-level directory.

# Add set-up func here for: GP = genesis_func.GenesisParser()

#GP = None

@pytest.fixture
def fresh_GP():
    """Ensure fresh instantiation of GenesisParser class.
    """
    GP = genesis_func.GenesisParser()
    yield GP
    #return GP


def test_get_empty_prob_list(fresh_GP):
    mylist = fresh_GP.get_prob_list("a_source", "a_sink")
    assert mylist == [] # As there won't be a list for this transition.


def test_missing_file(fresh_GP):
    with pytest.raises(FileNotFoundError):
        fresh_GP.parse_stt("tests/missing_file.txt")


def test_normal_stt_parse(fresh_GP):
    test_dict = fresh_GP.parse_stt("tests/sample_stt.txt")
    outer_keys = sorted(test_dict.keys())
    assert outer_keys == ["cin1", "normal", "occult"]

    # Each list should have one tuple only:
    assert test_dict["cin1"]["occult"] == [("12", "80", "0.3")]
    assert test_dict["normal"]["cin1"] == [("12", "80", "0.2")]
    assert test_dict["occult"]["treated"] == [("12", "80", "0.07")]

    # We expect a list of 2 tuples next:
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


def test_duplicate_lines():
    # Need a transition checking function to catch this sort of thing.
    # Like in the Perl version. 
    # TODO Implement GenesisParser.check_transitions() function
    #GP = genesis_func.GenesisParser()
    #test_dict = GP.parse_stt("tests/stt_dup_lines.txt")
    #outer_keys = sorted(test_dict.keys())
    #assert outer_keys == ["occult"]
    #inner_dict = test_dict["occult"]
    #inner_keys = sorted(inner_dict.keys())
    #assert inner_keys == ["symp"]
    #assert test_dict["occult"]["symp"] == [("12", "20", "0.09")]
    pass


# https://realpython.com/pytest-python-testing/#parametrization-combining-tests
@pytest.mark.parametrize("tup", [
   ("40", "20", "0.06"),
   ("-27", "40", "0.05"),
   # ("20", "40", "0.06"),  # Use this "good" tuple to check failure of this test!
])
def test_bad_tuple(fresh_GP, tup: tuple):
    #GP = genesis_func.GenesisParser()
    assert fresh_GP.bad_tuple(tup)
