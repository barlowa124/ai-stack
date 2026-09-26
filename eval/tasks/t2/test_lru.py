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
    c.put(1, 'b')
    c.put(2, 'x')
    c.put(3, 'y')
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
