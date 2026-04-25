import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mini_project/controllers/timer_session_controller.dart';
import 'package:mini_project/services/firestore.dart';
import 'package:mini_project/screens/note_upload.dart';
import 'package:mini_project/theme/zen_colors.dart';
import 'package:mini_project/widgets/timer/timer_activity_card.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final TimerSessionController _controller = TimerSessionController(
    fireStoreService: FireStoreService(),
  );

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _initializeTimerSession();
    
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _initializeTimerSession() async {
    final initResult = await _controller.initialize(
      userId: FirebaseAuth.instance.currentUser?.uid,
      onAutoPaused: _showAutoPausedMessage,
      onTimerElapsed: _handleTimerElapsed,
    );

    if (!mounted) return;

    if (initResult.errorMessage != null) {
      _showSnackBar(initResult.errorMessage!);
    }

    if (initResult.shouldRedirect) {
      Navigator.pushReplacementNamed(context, initResult.redirectRoute!);
    }
  }

  void _showAutoPausedMessage(String reason) {
    if (!mounted) return;
    _showSnackBar(reason);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleTimerElapsed() async {
    await _completeAndNavigateHome();
  }

  Future<void> _completeAndNavigateHome() async {
    final finishResult = await _controller.finishActivity();
    if (!mounted) return;

    _showSnackBar(finishResult.message);
    if (finishResult.success && _controller.activityId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => NoteUploadScreen(
            activityId: _controller.activityId!,
          ),
        ),
      );
    } else if (finishResult.success) {
       Navigator.pushReplacementNamed(context, 'home');
    }
  }

  Future<bool> _handleWillPop() async {
    if (!_controller.isTimerSessionActive) {
      return true;
    }

    _showSnackBar(
      'Timer masih aktif. Selesaikan atau stop timer dulu sebelum keluar.',
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel = _controller.isPaused ? 'PAUSED' : 'RUNNING';
    final statusColor = _controller.isPaused
        ? ZenColors.primary
        : ZenColors.secondary;

    return WillPopScope(
      onWillPop: _handleWillPop,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Timer Fokus'),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ZenColors.background,
                Color(0xFFF2EFE8),
                ZenColors.accent,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _controller.isLoading
                    ? const CircularProgressIndicator(color: ZenColors.primary)
                    : TimerActivityCard(
                        statusLabel: statusLabel,
                        statusColor: statusColor,
                        activityName: _controller.activityName,
                        activityDescription: _controller.activityDescription,
                        remainingTimeText: _controller.formatSeconds(
                          _controller.remainingSeconds,
                        ),
                        progressValue: _controller.progressValue,
                        isPaused: _controller.isPaused,
                        isFinishing: _controller.isFinishing,
                        onPauseResume: _controller.togglePauseResume,
                        onStop: _completeAndNavigateHome,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
