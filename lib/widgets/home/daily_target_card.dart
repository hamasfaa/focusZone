import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mini_project/services/firestore.dart';
import 'package:mini_project/theme/zen_colors.dart';

class DailyTargetCard extends StatelessWidget {
  const DailyTargetCard({
    super.key,
    required this.activities,
    required this.targetMinutes,
    required this.onEditTarget,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> activities;
  final int targetMinutes;
  final VoidCallback onEditTarget;

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

  DateTime? _resolveCompletedDate(Map<String, dynamic> data) {
    final completedAt = data['completedAt'];
    if (completedAt is Timestamp) {
      return completedAt.toDate();
    }

    final createdAt = data['createdAt'];
    if (createdAt is Timestamp) {
      return createdAt.toDate();
    }

    return null;
  }

  DateTime _dateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  Map<DateTime, int> _buildDailySeconds() {
    final Map<DateTime, int> totals = {};

    for (final doc in activities) {
      final data = doc.data();
      final status = (data['status'] ?? '').toString();
      if (status != FireStoreService.activityStatusCompleted) {
        continue;
      }

      final completedDate = _resolveCompletedDate(data);
      if (completedDate == null) {
        continue;
      }

      final key = _dateOnly(completedDate);
      final durationSeconds = _resolveDurationInSeconds(data);
      totals[key] = (totals[key] ?? 0) + durationSeconds;
    }

    return totals;
  }

  int _calculateStreak(Map<DateTime, int> dailySeconds) {
    if (targetMinutes <= 0) {
      return 0;
    }

    final targetSeconds = targetMinutes * 60;
    final today = _dateOnly(DateTime.now());

    var streak = 0;
    var offset = 0;
    while (true) {
      final date = today.subtract(Duration(days: offset));
      final seconds = dailySeconds[date] ?? 0;
      if (seconds < targetSeconds) {
        break;
      }
      streak += 1;
      offset += 1;
    }

    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final dailySeconds = _buildDailySeconds();
    final today = _dateOnly(DateTime.now());
    final todaySeconds = dailySeconds[today] ?? 0;
    final todayMinutes = (todaySeconds / 60).floor();
    final streak = _calculateStreak(dailySeconds);

    final hasTarget = targetMinutes > 0;
    final progress = hasTarget
        ? (todayMinutes / targetMinutes).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ZenColors.accent, width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Target Harian',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ZenColors.text,
                ),
              ),
              TextButton.icon(
                onPressed: onEditTarget,
                icon: const Icon(Icons.edit, size: 18),
                label: Text(hasTarget ? 'Ubah' : 'Atur'),
                style: TextButton.styleFrom(
                  foregroundColor: ZenColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasTarget
                ? 'Hari ini: $todayMinutes / $targetMinutes menit'
                : 'Target belum diatur',
            style: TextStyle(
              color: ZenColors.text.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              color: ZenColors.primary,
              backgroundColor: ZenColors.accent.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: ZenColors.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Streak: $streak hari',
                style: const TextStyle(
                  color: ZenColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
