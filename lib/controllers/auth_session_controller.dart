import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthSessionController extends ChangeNotifier {
  AuthSessionController({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  bool _isLoading = false;
  String _errorMessage = '';

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<bool> login({required String email, required String password}) {
    return _runAuthAction(() {
      return _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    });
  }

  Future<bool> register({required String email, required String password}) {
    return _runAuthAction(() {
      return _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    });
  }

  Future<bool> _runAuthAction(Future<void> Function() action) async {
    if (_isLoading) {
      return false;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    var success = false;
    try {
      await action();
      success = true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.code;
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return success;
  }
}
