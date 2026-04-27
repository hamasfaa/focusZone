import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:mini_project/services/firestore.dart';

class HomeRouteCheckResult {
  const HomeRouteCheckResult({this.redirectRoute, this.errorMessage});

  final String? redirectRoute;
  final String? errorMessage;

  bool get shouldRedirect => redirectRoute != null;

  static const stay = HomeRouteCheckResult();
}

class HomeSessionController extends ChangeNotifier {
  HomeSessionController({
    required FireStoreService fireStoreService,
    FirebaseAuth? auth,
  }) : _fireStoreService = fireStoreService,
       _auth = auth ?? FirebaseAuth.instance;

  final FireStoreService _fireStoreService;
  final FirebaseAuth _auth;

  bool _isCheckingRunningActivity = true;
  bool _isRedirectingToTimer = false;

  bool get isCheckingRunningActivity => _isCheckingRunningActivity;
  String? get currentUserId => _auth.currentUser?.uid;
  FireStoreService get fireStoreService => _fireStoreService;

  Future<HomeRouteCheckResult> checkRouteOnHomeEntry() async {
    if (_isRedirectingToTimer) {
      return HomeRouteCheckResult.stay;
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _isCheckingRunningActivity = false;
      notifyListeners();
      return const HomeRouteCheckResult(redirectRoute: 'login');
    }

    try {
      final runningActivity = await _fireStoreService.getRunningActivityForUser(
        currentUser.uid,
      );

      if (runningActivity != null) {
        _isRedirectingToTimer = true;
        _isCheckingRunningActivity = false;
        notifyListeners();
        return const HomeRouteCheckResult(redirectRoute: 'timer');
      }
    } catch (_) {
      _isCheckingRunningActivity = false;
      notifyListeners();
      return const HomeRouteCheckResult(
        errorMessage: 'Gagal memeriksa aktivitas running.',
      );
    }

    _isCheckingRunningActivity = false;
    notifyListeners();
    return HomeRouteCheckResult.stay;
  }

  Future<void> saveRunningActivity({
    required String name,
    required String description,
    required int durationInSeconds,
    String? categoryId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Sesi login tidak ditemukan.');
    }

    await _fireStoreService.addActivity(
      name: name,
      description: description,
      durationInSeconds: durationInSeconds,
      userId: currentUser.uid,
      status: FireStoreService.activityStatusRunning,
      categoryId: categoryId,
    );
  }

  Future<void> logout() {
    return _auth.signOut();
  }
}
