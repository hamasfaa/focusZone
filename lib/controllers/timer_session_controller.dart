import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mini_project/services/firestore.dart';
import 'package:sensors_plus/sensors_plus.dart';

class TimerInitResult {
  const TimerInitResult({this.redirectRoute, this.errorMessage});

  final String? redirectRoute;
  final String? errorMessage;

  bool get shouldRedirect => redirectRoute != null;

  static const ready = TimerInitResult();
}

class TimerFinishResult {
  const TimerFinishResult({required this.success, required this.message});

  final bool success;
  final String message;
}

class TimerSessionController extends ChangeNotifier {
  TimerSessionController({required FireStoreService fireStoreService})
    : _fireStoreService = fireStoreService;

  static const double _gyroMovementThreshold = 1;
  static const Duration _gyroTriggerCooldown = Duration(milliseconds: 1200);

  final FireStoreService _fireStoreService;

  Timer? _ticker;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  DateTime? _lastGyroTriggerAt;

  VoidCallback? _onAutoPaused;
  VoidCallback? _onTimerElapsed;

  bool _isLoading = true;
  bool _isFinishing = false;
  bool _isPaused = false;

  String? _activityId;
  String _activityName = '';
  String _activityDescription = '';
  int _totalSeconds = 0;
  int _remainingSeconds = 0;

  bool get isLoading => _isLoading;
  bool get isFinishing => _isFinishing;
  bool get isPaused => _isPaused;

  String get activityName => _activityName;
  String get activityDescription => _activityDescription;
  int get totalSeconds => _totalSeconds;
  int get remainingSeconds => _remainingSeconds;

  bool get isTimerSessionActive {
    return !_isLoading && !_isFinishing && _remainingSeconds > 0;
  }

  double get progressValue {
    if (_totalSeconds <= 0) {
      return 0;
    }

    final completedSeconds = (_totalSeconds - _remainingSeconds).clamp(
      0,
      _totalSeconds,
    );

    return completedSeconds / _totalSeconds;
  }

  String formatSeconds(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  Future<TimerInitResult> initialize({
    required String? userId,
    VoidCallback? onAutoPaused,
    VoidCallback? onTimerElapsed,
  }) async {
    _onAutoPaused = onAutoPaused;
    _onTimerElapsed = onTimerElapsed;

    if (userId == null) {
      _isLoading = false;
      notifyListeners();
      return const TimerInitResult(redirectRoute: 'login');
    }

    try {
      final runningActivity = await _fireStoreService.getRunningActivityForUser(
        userId,
      );

      if (runningActivity == null) {
        _isLoading = false;
        notifyListeners();
        return const TimerInitResult(redirectRoute: 'home');
      }

      final data = runningActivity.data();
      final totalSeconds = _resolveDurationInSeconds(data);

      _activityId = runningActivity.id;
      _activityName = (data['name'] ?? '') as String;
      _activityDescription = (data['description'] ?? '') as String;
      _totalSeconds = totalSeconds;
      _remainingSeconds = totalSeconds;
      _isLoading = false;
      notifyListeners();

      _startGyroscopeMonitor();
      _startTicker();

      return TimerInitResult.ready;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return const TimerInitResult(
        redirectRoute: 'home',
        errorMessage: 'Gagal memuat aktivitas running.',
      );
    }
  }

  void _startGyroscopeMonitor() {
    _gyroscopeSubscription?.cancel();
    _gyroscopeSubscription = gyroscopeEvents.listen(
      _handleGyroscopeEvent,
      onError: (_) {},
    );
  }

  void _handleGyroscopeEvent(GyroscopeEvent event) {
    if (_isLoading || _isFinishing || _isPaused || _remainingSeconds <= 0) {
      return;
    }

    final movementMagnitude = math.sqrt(
      (event.x * event.x) + (event.y * event.y) + (event.z * event.z),
    );

    if (movementMagnitude < _gyroMovementThreshold) {
      return;
    }

    final now = DateTime.now();
    if (_lastGyroTriggerAt != null &&
        now.difference(_lastGyroTriggerAt!) < _gyroTriggerCooldown) {
      return;
    }
    _lastGyroTriggerAt = now;

    pauseTimer();
    HapticFeedback.heavyImpact();
    _onAutoPaused?.call();
  }

  int _resolveDurationInSeconds(Map<String, dynamic> data) {
    final fromSeconds = data['durationInSeconds'];
    if (fromSeconds is int) {
      return fromSeconds;
    }
    if (fromSeconds is num) {
      return fromSeconds.toInt();
    }

    final fromMinutes = data['durationInMinutes'];
    if (fromMinutes is int) {
      return fromMinutes * 60;
    }
    if (fromMinutes is num) {
      return fromMinutes.toInt() * 60;
    }

    return 0;
  }

  void _startTicker() {
    _ticker?.cancel();

    if (_remainingSeconds <= 0) {
      _onTimerElapsed?.call();
      return;
    }

    _isPaused = false;
    notifyListeners();

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _remainingSeconds = 0;
        notifyListeners();
        _onTimerElapsed?.call();
        return;
      }

      _remainingSeconds -= 1;
      notifyListeners();
    });
  }

  void pauseTimer() {
    if (_isPaused || _isFinishing) return;

    _ticker?.cancel();
    _isPaused = true;
    notifyListeners();
  }

  void resumeTimer() {
    if (!_isPaused || _isFinishing) return;

    _startTicker();
  }

  void togglePauseResume() {
    if (_isPaused) {
      resumeTimer();
      return;
    }

    pauseTimer();
  }

  Future<TimerFinishResult> finishActivity() async {
    if (_isFinishing) {
      return const TimerFinishResult(
        success: false,
        message: 'Sedang menyelesaikan aktivitas...',
      );
    }

    if (_activityId == null) {
      return const TimerFinishResult(
        success: false,
        message: 'Aktivitas running tidak ditemukan.',
      );
    }

    _isFinishing = true;
    _isPaused = false;
    _ticker?.cancel();
    notifyListeners();

    try {
      await _fireStoreService.updateActivityStatus(
        activityId: _activityId!,
        status: FireStoreService.activityStatusCompleted,
      );

      return const TimerFinishResult(
        success: true,
        message: 'Timer selesai. Aktivitas ditandai selesai.',
      );
    } catch (e) {
      _isFinishing = false;
      notifyListeners();

      if (_remainingSeconds > 0) {
        _startTicker();
      }

      return TimerFinishResult(
        success: false,
        message: 'Gagal update status: $e',
      );
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _gyroscopeSubscription?.cancel();
    super.dispose();
  }
}
