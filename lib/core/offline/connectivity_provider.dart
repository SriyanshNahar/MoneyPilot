import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../supabase/supabase_config.dart';
import 'offline_cache.dart';

class ConnectivityState {
  const ConnectivityState({required this.online, required this.pendingWrites});
  final bool online;
  final int pendingWrites;
}

/// Tracks online/offline state and flushes the offline write queue
/// (see OfflineCache.pendingWrites) as soon as connectivity returns.
/// Watched app-wide from app.dart so the retry queue drains even if the
/// user isn't currently on the screen that queued the write.
class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  ConnectivityNotifier() : super(const ConnectivityState(online: true, pendingWrites: 0)) {
    _init();
  }

  bool _flushing = false;

  Future<void> _init() async {
    final results = await Connectivity().checkConnectivity();
    _update(_isOnline(results));

    Connectivity().onConnectivityChanged.listen((results) {
      final wasOffline = !state.online;
      _update(_isOnline(results));
      if (wasOffline && state.online) {
        flushPendingWrites();
      }
    });
  }

  bool _isOnline(List<ConnectivityResult> results) => results.any((r) => r != ConnectivityResult.none);

  void _update(bool online) {
    state = ConnectivityState(online: online, pendingWrites: OfflineCache.instance.pendingWriteCount);
  }

  /// Call right after enqueueing a write while offline so the banner's
  /// count updates immediately instead of waiting for the next
  /// connectivity change event.
  void refreshPendingCount() => _update(state.online);

  /// Replays queued expense/event inserts made while offline. Best-effort:
  /// a write that fails again (e.g. still offline, or a genuine server
  /// error) just stays queued for the next reconnect instead of being lost.
  Future<void> flushPendingWrites() async {
    if (_flushing) return;
    _flushing = true;
    try {
      for (final write in OfflineCache.instance.pendingWrites) {
        try {
          await supabase.from(write.table).insert(write.payload);
          await OfflineCache.instance.removeWrite(write.id);
        } catch (_) {
          // Leave it queued — will retry on the next reconnect or app start.
        }
      }
    } finally {
      _flushing = false;
      _update(state.online);
    }
  }
}

final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, ConnectivityState>(
  (ref) => ConnectivityNotifier(),
);
