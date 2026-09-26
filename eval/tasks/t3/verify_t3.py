import sys, math
sys.path.insert(0, '.')
from parser import evaluate

cases = {
    "2 + 3 * (4 - 1)": 11.0,
    "1+2*3": 7.0,
    "(1+2)*3": 9.0,
    "10 / 4": 2.5,
    "-5 + 3": -2.0,
    "-(2+3)": -5.0,
    "2 * -3": -6.0,
    "   42  ": 42.0,
    "3.5 * 2": 7.0,
    "((2))": 2.0,
}
for expr, want in cases.items():
    got = evaluate(expr)
    assert math.isclose(got, want, rel_tol=1e-9), f"{expr}: got {got}, want {want}"

try:
    evaluate("8 / (2 - 2)")
    raise AssertionError("division by zero did not raise")
except ZeroDivisionError:
    pass

try:
    evaluate("2 +")
    raise AssertionError("malformed input did not raise")
except Exception:
    pass
print('PASS')
