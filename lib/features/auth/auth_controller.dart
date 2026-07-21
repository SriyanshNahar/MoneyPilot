import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_config.dart';

/// Direct port of src/lib/auth.tsx — exposes the current session/user and
/// a loading flag while the initial session is being resolved.
class AuthState {
  const AuthState({this.session, this.loading = true});
  final Session? session;
  final bool loading;
  User? get user => session?.user;

  AuthState copyWith({Session? session, bool clearSession = false, bool? loading}) {
    return AuthState(
      session: clearSession ? null : (session ?? this.session),
      loading: loading ?? this.loading,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState()) {
    _init();
  }

  void _init() {
    // Subscribe first to avoid missed events, then resolve the current session.
    supabase.auth.onAuthStateChange.listen((data) {
      state = AuthState(session: data.session, loading: false);
    });
    final current = supabase.auth.currentSession;
    state = AuthState(session: current, loading: false);
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(),
);
