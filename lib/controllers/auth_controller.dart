import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_firebase_hooks/repositories/auth_repo.dart';

final authControllerProvider = StateNotifierProvider<AuthController, User?>(
  (ref) => AuthController(ref.read)..appStarted(),
);

class AuthController extends StateNotifier<User?> {
  AuthController(this._reader) : super(null) {
    _authStateChangesSubscription?.cancel();
    _authStateChangesSubscription = _reader(authRepoProvider)
        .authStateChanges
        .listen((user) => state = user);
  }

  final Reader _reader;
  StreamSubscription<User?>? _authStateChangesSubscription;

  void appStarted() async {
    final user = _reader(authRepoProvider).getCurrentUser();

    if (user == null) {
      await _reader(authRepoProvider).signInAnonymously();
    }
  }

  void signOut() async {
    await _reader(authRepoProvider).signOut();
  }

  @override
  void dispose() {
    _authStateChangesSubscription?.cancel();
    super.dispose();
  }
}
