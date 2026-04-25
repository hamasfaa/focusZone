import 'package:flutter/material.dart';
import 'package:mini_project/services/firestore.dart';
import 'package:mini_project/services/storage_service.dart';
import 'package:mini_project/theme/zen_colors.dart';

class ActivityDetailSheet extends StatelessWidget {
  const ActivityDetailSheet({
    super.key,
    required this.activityId,
    required this.title,
    required this.description,
    required this.durationText,
    required this.timeText,
    required this.noteText,
    required this.noteImageUrls,
  });

  final String activityId;
  final String title;
  final String description;
  final String durationText;
  final String timeText;
  final String noteText;
  final List<String> noteImageUrls;

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Aktivitas?'),
          content: const Text('Aktivitas ini beserta semua foto lampirannya akan dihapus permanen.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // close dialog
                
                try {
                  if (noteImageUrls.isNotEmpty) {
                    await StorageService().deleteActivityImages(noteImageUrls);
                  }
                  await FireStoreService().deleteActivity(activityId);
                  
                  if (context.mounted) {
                    Navigator.pop(context); // close sheet
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Aktivitas berhasil dihapus')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal menghapus: $e')),
                    );
                  }
                }
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: ZenColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: ZenColors.text,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _confirmDelete(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 18,
                          color: ZenColors.secondary.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          durationText,
                          style: const TextStyle(
                            color: ZenColors.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.schedule_rounded,
                          size: 18,
                          color: ZenColors.secondary.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            timeText,
                            style: TextStyle(
                              color: ZenColors.text.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 15,
                          color: ZenColors.text.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(color: ZenColors.accent),
                    ),
                    const Text(
                      'Catatan Sesi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: ZenColors.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (noteText.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ZenColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: ZenColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          noteText,
                          style: const TextStyle(
                            color: ZenColors.text,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      )
                    else if (noteImageUrls.isEmpty)
                      Text(
                        'Tidak ada catatan untuk sesi ini.',
                        style: TextStyle(
                          color: ZenColors.text.withValues(alpha: 0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    if (noteImageUrls.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Lampiran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: ZenColors.text,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: noteImageUrls.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _showFullScreenImage(context, noteImageUrls[index]),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                noteImageUrls[index],
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 200,
                                  color: ZenColors.accent.withValues(alpha: 0.3),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: ZenColors.primary,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  color: ZenColors.accent,
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('Gagal memuat gambar', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
