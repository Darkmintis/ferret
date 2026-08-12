import 'package:flutter/foundation.dart';

import 'ferret_entry.dart';

/// In-memory ring buffer of captured calls.
///
/// Newest entries are first. When [maxEntries] is exceeded, the oldest entry
/// is dropped.
class FerretStore extends ChangeNotifier {
  FerretStore({required int maxEntries})
    : assert(maxEntries > 0),
      _maxEntries = maxEntries;

  int _maxEntries;
  final List<FerretEntry> _entries = <FerretEntry>[];

  int get maxEntries => _maxEntries;

  /// Newest-first snapshot.
  List<FerretEntry> get entries => List<FerretEntry>.unmodifiable(_entries);

  int get length => _entries.length;

  bool get isEmpty => _entries.isEmpty;

  FerretEntry? operator [](int index) => _entries[index];

  FerretEntry? getById(String id) {
    for (final entry in _entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  void setMaxEntries(int value) {
    assert(value > 0);
    _maxEntries = value;
    _trim();
    notifyListeners();
  }

  /// Inserts [entry] at the front of the buffer.
  void add(FerretEntry entry) {
    _entries.insert(0, entry);
    _trim();
    notifyListeners();
  }

  /// Replaces an existing entry by [id]. Returns `false` if not found.
  bool update(String id, FerretEntry Function(FerretEntry current) transform) {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index < 0) return false;
    _entries[index] = transform(_entries[index]);
    notifyListeners();
    return true;
  }

  void remove(String id) {
    final before = _entries.length;
    _entries.removeWhere((e) => e.id == id);
    if (_entries.length != before) {
      notifyListeners();
    }
  }

  void clear() {
    if (_entries.isEmpty) return;
    _entries.clear();
    notifyListeners();
  }

  void _trim() {
    while (_entries.length > _maxEntries) {
      _entries.removeLast();
    }
  }

  @override
  void dispose() {
    _entries.clear();
    super.dispose();
  }
}
