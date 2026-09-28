from lru import LRUCache


def test_basic():
    c = LRUCache(2)
    c.put(1, 'a')
    c.put(2, 'b')
    assert c.get(1) == 'a'
    c.put(3, 'c')
    assert c.get(2) == -1
    assert c.get(1) == 'a'


def test_update_existing():
    c = LRUCache(2)
    c.put(1, 'a')
    c.put(2, 'x')
    c.put(1, 'b')   # updating refreshes recency: 2 is now oldest
    c.put(3, 'y')   # evicts 2, not 1
    assert c.get(1) == 'b'
    assert c.get(2) == -1


def test_eviction_order():
    c = LRUCache(2)
    c.put('a', 1)
    c.put('b', 2)
    c.put('c', 3)
    c.put('d', 4)
    assert c.get('a') == -1
    assert c.get('b') == -1
    assert c.get('c') == 3
    assert c.get('d') == 4


def test_get_refreshes_recency():
    c = LRUCache(3)
    c.put(1, 1)
    c.put(2, 2)
    c.put(3, 3)
    c.get(1)          # 1 is now most-recently-used
    c.put(4, 4)       # must evict 2, not 1
    assert c.get(2) == -1
    assert c.get(1) == 1


def test_capacity_one():
    c = LRUCache(1)
    c.put('x', 10)
    c.put('y', 20)
    assert c.get('x') == -1
    assert c.get('y') == 20


def test_get_missing_returns_minus_one():
    c = LRUCache(2)
    assert c.get('absent') == -1
    c.put('k', 'v')
    assert c.get('absent') == -1
    assert c.get('k') == 'v'   # misses must not corrupt stored entries
