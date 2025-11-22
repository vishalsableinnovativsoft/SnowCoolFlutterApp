import '../services/customer_api.dart';

// Lightweight in-memory store for filtering and paging customer lists.
class CustomerStore {
  final List<CustomerDTO> _original;
  List<CustomerDTO> _filtered = [];

  CustomerStore(this._original) {
    _filtered = List.from(_original);
  }

  void applyFilter(String q) {
    final query = q.toLowerCase().trim();
    if (query.isEmpty) {
      _filtered = List.from(_original);
      return;
    }
    _filtered = _original.where((c) {
      final name = c.name.toLowerCase();
      final mobile = c.contactNumber.toLowerCase();
      final email = (c.email ?? '').toLowerCase();
      final addr = (c.address ?? '').toLowerCase();
      return name.contains(query) ||
          mobile.contains(query) ||
          email.contains(query) ||
          addr.contains(query);
    }).toList();
  }

  int get filteredCount => _filtered.length;

  /// Return a safe sublist [start,end) of the filtered items.
  List<CustomerDTO> getRange(int start, int end) {
    if (start >= _filtered.length) return <CustomerDTO>[];
    final safeEnd = end > _filtered.length ? _filtered.length : end;
    return _filtered.sublist(start, safeEnd);
  }
}