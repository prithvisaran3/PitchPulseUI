import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/api_client.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiClient _api = ApiClient();

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _appUser;
  String? _error;
  bool _demoMode = false;

  AuthStatus get status => _status;
  AppUser? get appUser => _appUser;
  String? get error => _error;
  bool get demoMode => _demoMode;
  bool get isLoggedIn => _status == AuthStatus.authenticated;
  bool get isAdmin => _appUser?.isAdmin ?? false;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      _status = AuthStatus.unauthenticated;
      _appUser = null;
    } else {
      await _fetchMe(user);
    }
    notifyListeners();
  }

  Future<void> _fetchMe(User firebaseUser) async {
    try {
      final data = await _api.get('/me') as Map<String, dynamic>;
      _appUser = AppUser.fromJson(data);
      _status = AuthStatus.authenticated;
    } catch (_) {
      // Fallback: build minimal AppUser from Firebase token claims or demo
      // Determine role from email for demo purposes
      final email = firebaseUser.email ?? '';
      final role = email.contains('admin') ? 'admin' : 'manager';
      _appUser = AppUser.demo(
        uid: firebaseUser.uid,
        email: email,
        role: role,
      );
      _status = AuthStatus.authenticated;
    }
  }

  Future<void> signIn(String email, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      _error = _friendlyError(e.code);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password, String role) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      // Backend will handle role assignment on /me
    } on FirebaseAuthException catch (e) {
      _error = _friendlyError(e.code);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  void setDemoMode(bool value) {
    _demoMode = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found': return 'No account found with this email.';
      case 'wrong-password': return 'Incorrect password. Please try again.';
      case 'invalid-email': return 'Please enter a valid email address.';
      case 'user-disabled': return 'This account has been disabled.';
      case 'email-already-in-use': return 'An account already exists for this email.';
      case 'weak-password': return 'Password should be at least 6 characters.';
      case 'too-many-requests': return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed': return 'Network error. Check your connection.';
      default: return 'Authentication failed. Please try again.';
    }
  }
}
