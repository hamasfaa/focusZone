import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mini_project/services/firestore.dart';
import 'package:mini_project/theme/zen_colors.dart';
import 'package:mini_project/widgets/home/activity_detail_sheet.dart';
import 'package:mini_project/widgets/home/home_history_placeholder_card.dart';

class HomeActivityHistoryList extends StatelessWidget {
  const HomeActivityHistoryList({
    super.key,
    required this.userId,
    required this.fireStoreService,
  });

  final String userId;
  final FireStoreService fireStoreService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: fireStoreService.streamActivitiesForUser(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: ZenColors.primary),
          );
        }

        if (snapshot.hasError) {
          return _HistoryErrorCard(message: snapshot.error.toString());
        }

        final docs =
            (snapshot.data ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                .where(
                  (doc) =>
                      (doc.data()['status'] ?? '') ==
                      FireStoreService.activityStatusCompleted,
                )
                .toList();

        if (docs.isEmpty) {
          return const HomeHistoryPlaceholderCard();
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final doc = docs[index];
            return _HistoryActivityCard(
              activityId: doc.id,
              data: doc.data(),
            );
          },
        );
      },
    );
  }
}

class _HistoryActivityCard extends StatelessWidget {
  const _HistoryActivityCard({
    required this.activityId,
    required this.data,
  });

  final String activityId;
  final Map<String, dynamic> data;

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(hours)}:${twoDigits(minutes)}';
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

  String _formatTime(Map<String, dynamic> data) {
    final completedAt = data['completedAt'];
    final createdAt = data['createdAt'];

    Timestamp? timestamp;
    if (completedAt is Timestamp) {
      timestamp = completedAt;
    } else if (createdAt is Timestamp) {
      timestamp = createdAt;
    }

    if (timestamp == null) {
      return '-';
    }

    final date = timestamp.toDate();
    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year} ${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }

  void _showDetail(
    BuildContext context,
    String activityId,
    String title,
    String description,
    String durationText,
    String timeText,
    String noteText,
    List<String> noteImageUrls,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ActivityDetailSheet(
        activityId: activityId,
        title: title,
        description: description,
        durationText: durationText,
        timeText: timeText,
        noteText: noteText,
        noteImageUrls: noteImageUrls,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = (data['name'] ?? 'Tanpa Judul').toString();
    final description = (data['description'] ?? '').toString();
    final durationText = _formatDuration(_resolveDurationInSeconds(data));
    final timeText = _formatTime(data);
    
    final noteText = (data['noteText'] ?? '').toString();
    final List<String> noteImageUrls = List<String>.from(data['noteImageUrls'] ?? []);
    final hasNoteOrImage = noteText.isNotEmpty || noteImageUrls.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDetail(
          context,
          activityId,
          title,
          description,
          durationText,
          timeText,
          noteText,
          noteImageUrls,
        ),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.84),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ZenColors.accent, width: 1.1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: ZenColors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (hasNoteOrImage) ...[
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: ZenColors.secondary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        noteImageUrls.isNotEmpty ? Icons.image_rounded : Icons.notes_rounded,
                        size: 14,
                        color: ZenColors.secondary,
                      ),
                    ),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ZenColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Text(
                      'SELESAI',
                      style: TextStyle(
                        color: ZenColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(color: ZenColors.text.withValues(alpha: 0.75)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: ZenColors.secondary.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    durationText,
                    style: const TextStyle(
                      color: ZenColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: ZenColors.secondary.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      timeText,
                      style: TextStyle(
                        color: ZenColors.text.withValues(alpha: 0.75),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryErrorCard extends StatelessWidget {
  const _HistoryErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFB4533C), width: 1.2),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Gagal memuat history: $message',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFB4533C),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
