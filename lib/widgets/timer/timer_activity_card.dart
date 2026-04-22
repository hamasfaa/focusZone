import 'package:flutter/material.dart';
import 'package:mini_project/theme/zen_colors.dart';
import 'package:mini_project/widgets/timer/timer_action_icon_button.dart';

class TimerActivityCard extends StatelessWidget {
  const TimerActivityCard({
    super.key,
    required this.statusLabel,
    required this.statusColor,
    required this.activityName,
    required this.activityDescription,
    required this.remainingTimeText,
    required this.progressValue,
    required this.isPaused,
    required this.isFinishing,
    required this.onPauseResume,
    required this.onStop,
  });

  final String statusLabel;
  final Color statusColor;
  final String activityName;
  final String activityDescription;
  final String remainingTimeText;
  final double progressValue;
  final bool isPaused;
  final bool isFinishing;
  final VoidCallback onPauseResume;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 420,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ZenColors.accent, width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sedang Berjalan',
                style: TextStyle(
                  color: ZenColors.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            activityName,
            style: const TextStyle(
              color: ZenColors.text,
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),
          if (activityDescription.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              activityDescription,
              style: TextStyle(color: ZenColors.text.withValues(alpha: 0.74)),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            remainingTimeText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ZenColors.text,
              fontSize: 44,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progressValue,
              color: ZenColors.primary,
              backgroundColor: ZenColors.accent.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TimerActionIconButton(
                tooltip: isPaused ? 'Lanjutkan' : 'Pause',
                icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                onPressed: isFinishing ? null : onPauseResume,
                backgroundColor: ZenColors.primary,
              ),
              const SizedBox(width: 14),
              TimerActionIconButton(
                tooltip: 'Stop',
                icon: Icons.stop_rounded,
                onPressed: isFinishing ? null : onStop,
                backgroundColor: const Color(0xFFB4533C),
                isLoading: isFinishing,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
