import sys
sys.path.insert(0, '.')
import store, report

assert store.DISCOUNT == 0.9
assert store.get_item('apple') == 9.0
assert store.get_item('nope') is None
assert report.total() == 27.0
print('PASS')
