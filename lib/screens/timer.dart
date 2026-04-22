import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mini_project/services/firestore.dart';
import 'package:mini_project/theme/zen_colors.dart';
import 'package:mini_project/widgets/timer/timer_activity_card.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final FireStoreService _fireStoreService = FireStoreService();

  Timer? _ticker;
  bool _isLoading = true;
  bool _isFinishing = false;
  bool _isPaused = false;

  String? _activityId;
  String _activityName = '';
  String _activityDescription = '';
  int _totalSeconds = 0;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadRunningActivity();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadRunningActivity() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, 'login');
      return;
    }

    try {
      final runningActivity = await _fireStoreService.getRunningActivityForUser(
        currentUser.uid,
      );

      if (!mounted) return;

      if (runningActivity == null) {
        Navigator.pushReplacementNamed(context, 'home');
        return;
      }

      final data = runningActivity.data();
      final totalSeconds = _resolveDurationInSeconds(data);

      setState(() {
        _activityId = runningActivity.id;
        _activityName = (data['name'] ?? '') as String;
        _activityDescription = (data['description'] ?? '') as String;
        _totalSeconds = totalSeconds;
        _remainingSeconds = totalSeconds;
        _isLoading = false;
      });

      _startTicker();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat aktivitas running.')),
      );
      Navigator.pushReplacementNamed(context, 'home');
    }
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

  String _formatSeconds(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  void _startTicker() {
    _ticker?.cancel();

    if (_remainingSeconds <= 0) {
      _finishActivity();
      return;
    }

    _isPaused = false;

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
        });
        _finishActivity();
        return;
      }

      setState(() {
        _remainingSeconds -= 1;
      });
    });
  }

  void _pauseTimer() {
    if (_isPaused || _isFinishing) return;

    _ticker?.cancel();
    setState(() {
      _isPaused = true;
    });
  }

  void _resumeTimer() {
    if (!_isPaused || _isFinishing) return;

    _startTicker();
    if (mounted) {
      setState(() {
        _isPaused = false;
      });
    }
  }

  void _togglePauseResume() {
    if (_isPaused) {
      _resumeTimer();
      return;
    }

    _pauseTimer();
  }

  Future<void> _finishActivity() async {
    if (_isFinishing || _activityId == null) return;

    setState(() {
      _isFinishing = true;
      _isPaused = false;
    });

    _ticker?.cancel();

    try {
      await _fireStoreService.updateActivityStatus(
        activityId: _activityId!,
        status: FireStoreService.activityStatusCompleted,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Timer selesai. Aktivitas ditandai selesai.'),
        ),
      );
      Navigator.pushReplacementNamed(context, 'home');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal update status: $e')));

      setState(() {
        _isFinishing = false;
      });

      if (_remainingSeconds > 0) {
        _startTicker();
      }
    }
  }

  double get _progressValue {
    if (_totalSeconds <= 0) {
      return 0;
    }

    final completedSeconds = (_totalSeconds - _remainingSeconds).clamp(
      0,
      _totalSeconds,
    );
    return completedSeconds / _totalSeconds;
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel = _isPaused ? 'PAUSED' : 'RUNNING';
    final statusColor = _isPaused ? ZenColors.primary : ZenColors.secondary;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Timer Fokus'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ZenColors.background, Color(0xFFF2EFE8), ZenColors.accent],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _isLoading
                  ? const CircularProgressIndicator(color: ZenColors.primary)
                  : TimerActivityCard(
                      statusLabel: statusLabel,
                      statusColor: statusColor,
                      activityName: _activityName,
                      activityDescription: _activityDescription,
                      remainingTimeText: _formatSeconds(_remainingSeconds),
                      progressValue: _progressValue,
                      isPaused: _isPaused,
                      isFinishing: _isFinishing,
                      onPauseResume: _togglePauseResume,
                      onStop: _finishActivity,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
