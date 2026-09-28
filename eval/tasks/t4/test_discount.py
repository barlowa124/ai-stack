import store
import report


def test_discount_constant():
    assert store.DISCOUNT == 0.9


def test_get_item_applies_discount():
    assert store.get_item('apple') == 9.0
    assert store.get_item('banana') == 4.5


def test_get_item_missing_returns_none():
    assert store.get_item('nope') is None


def test_report_totals_discounted_prices():
    assert report.total() == 27.0
