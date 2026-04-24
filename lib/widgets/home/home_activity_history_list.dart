import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mini_project/services/firestore.dart';
import 'package:mini_project/theme/zen_colors.dart';
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
            final activityData = docs[index].data();
            return _HistoryActivityCard(data: activityData);
          },
        );
      },
    );
  }
}

class _HistoryActivityCard extends StatelessWidget {
  const _HistoryActivityCard({required this.data});

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

  @override
  Widget build(BuildContext context) {
    final title = (data['name'] ?? 'Tanpa Judul').toString();
    final description = (data['description'] ?? '').toString();
    final durationText = _formatDuration(_resolveDurationInSeconds(data));
    final timeText = _formatTime(data);
    
    final noteText = (data['noteText'] ?? '').toString();
    final List<String> noteImageUrls = List<String>.from(data['noteImageUrls'] ?? []);

    return Container(
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
          if (noteText.isNotEmpty || noteImageUrls.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: ZenColors.accent),
            ),
            if (noteText.isNotEmpty)
              Text(
                noteText,
                style: const TextStyle(
                  color: ZenColors.text,
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
            if (noteImageUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: noteImageUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        noteImageUrls[index],
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                           return Container(
                             width: 48,
                             height: 48,
                             color: ZenColors.accent,
                             child: const Icon(Icons.broken_image, size: 20),
                           );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ],
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
