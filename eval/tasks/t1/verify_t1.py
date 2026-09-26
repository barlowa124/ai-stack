import sys
sys.path.insert(0, '.')
from utils import flatten, dedupe

assert flatten([1, [2, [3, [4]]], 5]) == [1, 2, 3, 4, 5]
assert flatten([]) == []
assert flatten([['a'], 'b']) == ['a', 'b']
assert dedupe([1, 2, 2, 3, 1]) == [1, 2, 3]
assert dedupe([[1], [2], [1], [3]]) == [[1], [2], [3]]   # unhashable items
assert dedupe(['a', 'b', 'a']) == ['a', 'b']
assert dedupe([]) == []
print('PASS')
