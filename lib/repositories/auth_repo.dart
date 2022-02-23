import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_firebase_hooks/general_providers.dart';
import 'package:riverpod_firebase_hooks/repositories/custom_exception.dart';

abstract class BaseAuthRepository {
  Stream<User?> get authStateChanges;

  Future<void> signInAnonymously();

  User? getCurrentUser();

  Future<void> signOut();
}

final authRepoProvider =
    Provider<AuthRepository>((ref) => AuthRepository(ref.read));

class AuthRepository implements BaseAuthRepository {
  const AuthRepository(this._read);

  final Reader _read;

  @override
  Stream<User?> get authStateChanges {
    try {
      return _read(firebaseAuthProvider).authStateChanges();
    } on FirebaseAuthException catch (err) {
      throw CustomException(message: err.message);
    }
  }

  @override
  Future<void> signInAnonymously() async {
    try {
      await _read(firebaseAuthProvider).signInAnonymously();
    } on FirebaseAuthException catch (err) {
      throw CustomException(message: err.message);
    }
  }

  @override
  User? getCurrentUser() {
    try {
      return _read(firebaseAuthProvider).currentUser;
    } on FirebaseAuthException catch (err) {
      throw CustomException(message: err.message);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _read(firebaseAuthProvider).signOut();
      await signInAnonymously();
    } on FirebaseAuthException catch (err) {
      throw CustomException(message: err.message);
    }
  }
}
