import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Authentication wrapper around Firebase Auth.
class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FlutterSecureStorage? secureStorage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FirebaseAuth _auth;
  final FlutterSecureStorage _secureStorage;

  static const _uidKey = 'auth_uid';

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  String? get uid => _auth.currentUser?.uid;

  Future<UserCredential> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _persistUid(cred.user?.uid);
    return cred;
  }

  Future<UserCredential> signUp(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _persistUid(cred.user?.uid);
    return cred;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _secureStorage.delete(key: _uidKey);
  }

  Future<void> _persistUid(String? uid) async {
    if (uid == null) return;
    await _secureStorage.write(key: _uidKey, value: uid);
  }

  Future<String?> readStoredUid() => _secureStorage.read(key: _uidKey);
}
