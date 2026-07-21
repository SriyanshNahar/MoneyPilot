import 'package:hive_flutter/hive_flutter.dart';

/// Lightweight offline cache + pending-write queue backed by Hive.
///
/// No TypeAdapters/codegen needed — everything stored here is plain
/// JSON-safe data (Map/List/String/num/bool), which Hive supports natively.
/// This is deliberately simple: a cache-then-network read-through for the
/// screens that matter most offline (Dashboard, Activity), and a retry
/// queue for writes made while offline (Add Expense/Event).
class OfflineCache {
  OfflineCache._();
  static final OfflineCache instance = OfflineCache._();

  static const _cacheBoxName = 'mp_cache';
  static const _queueBoxName = 'mp_pending_writes';

  late Box _cacheBox;
  late Box _queueBox;
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    _cacheBox = await Hive.openBox(_cacheBoxName);
    _queueBox = await Hive.openBox(_queueBoxName);
    _ready = true;
  }

  // ── Read-through cache ────────────────────────────────────────────────

  /// Caches any JSON-safe [value] (a Map, or a Map with list-of-maps
  /// fields) under [key], with the time it was fetched, so a later offline
  /// read can fall back to it.
  Future<void> put(String key, Map<String, dynamic> value) async {
    if (!_ready) return;
    await _cacheBox.put(key, {
      'value': value,
      'cachedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Returns the last cached value for [key], or null if nothing was ever
  /// cached. Does not throw — a cache miss is a normal, expected outcome.
  CachedValue? get(String key) {
    if (!_ready) return null;
    final raw = _cacheBox.get(key);
    if (raw == null) return null;
    final map = Map<String, dynamic>.from(raw as Map);
    final value = _deepCopy(map['value']) as Map<String, dynamic>;
    final cachedAt = DateTime.tryParse(map['cachedAt'] as String? ?? '') ?? DateTime.now();
    return CachedValue(value: value, cachedAt: cachedAt);
  }

  /// Hive returns its internal Map/List types (not the plain dart:core
  /// ones) — normalize recursively so callers can treat this like any
  /// other decoded JSON.
  dynamic _deepCopy(dynamic v) {
    if (v is Map) return v.map((k, val) => MapEntry(k as String, _deepCopy(val)));
    if (v is List) return v.map(_deepCopy).toList();
    return v;
  }

  // ── Pending write queue (for offline expense/event inserts) ───────────

  Future<void> enqueueWrite(PendingWrite write) async {
    if (!_ready) return;
    await _queueBox.put(write.id, write.toJson());
  }

  Future<void> removeWrite(String id) async {
    if (!_ready) return;
    await _queueBox.delete(id);
  }

  List<PendingWrite> get pendingWrites {
    if (!_ready) return const [];
    return _queueBox.keys
        .map((k) => PendingWrite.fromJson(Map<String, dynamic>.from(_queueBox.get(k) as Map)))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  int get pendingWriteCount => _ready ? _queueBox.length : 0;
}

class CachedValue {
  const CachedValue({required this.value, required this.cachedAt});
  final Map<String, dynamic> value;
  final DateTime cachedAt;
}

/// A queued mutation that couldn't reach Supabase because the device was
/// offline. [table] + [payload] are replayed as a plain insert once
/// connectivity returns (see ConnectivityNotifier._flushPendingWrites).
class PendingWrite {
  PendingWrite({
    required this.id,
    required this.table,
    required this.payload,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String table;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'table': table,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PendingWrite.fromJson(Map<String, dynamic> j) => PendingWrite(
        id: j['id'] as String,
        table: j['table'] as String,
        payload: Map<String, dynamic>.from(j['payload'] as Map),
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''),
      );
}
