class LRUCache:
    def __init__(self, capacity):
        self.capacity = capacity
        self.data = {}
        self.order = []

    def get(self, key):
        if key not in self.data:
            return -1
        return self.data[key]

    def put(self, key, value):
        self.data[key] = value
        self.order.append(key)
        if len(self.order) > self.capacity:
            self.order.pop(0)
