import sys
sys.path.insert(0, '.')
from lru import LRUCache

c = LRUCache(2)
c.put(1, 'a'); c.put(2, 'b')
assert c.get(1) == 'a'
c.put(3, 'c')
assert c.get(2) == -1
assert c.get(1) == 'a'

c2 = LRUCache(2)
c2.put(1, 'a'); c2.put(2, 'x')
c2.put(1, 'b'); c2.put(3, 'y')   # re-put refreshes 1; 2 is evicted
assert c2.get(1) == 'b'
assert c2.get(2) == -1

c3 = LRUCache(3)
c3.put(1, 1); c3.put(2, 2); c3.put(3, 3)
c3.get(1); c3.put(4, 4)
assert c3.get(2) == -1
assert c3.get(1) == 1
print('PASS')
