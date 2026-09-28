import math

import pytest

from parser import evaluate


@pytest.mark.parametrize("expr,want", [
    ("2 + 3 * (4 - 1)", 11.0),
    ("1+2*3", 7.0),
    ("(1+2)*3", 9.0),
    ("10 / 4", 2.5),
    ("-5 + 3", -2.0),
    ("-(2+3)", -5.0),
    ("2 * -3", -6.0),
    ("   42  ", 42.0),
    ("3.5 * 2", 7.0),
    ("((2))", 2.0),
])
def test_evaluate(expr, want):
    assert math.isclose(evaluate(expr), want, rel_tol=1e-9)


def test_division_by_zero_raises():
    with pytest.raises(ZeroDivisionError):
        evaluate("8 / (2 - 2)")


def test_malformed_input_raises():
    with pytest.raises(Exception):
        evaluate("2 +")
