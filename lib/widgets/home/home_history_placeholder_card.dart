import 'package:flutter/material.dart';
import 'package:mini_project/theme/zen_colors.dart';

class HomeHistoryPlaceholderCard extends StatelessWidget {
  const HomeHistoryPlaceholderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ZenColors.accent, width: 1.2),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history_edu_rounded,
                size: 52,
                color: ZenColors.secondary.withValues(alpha: 0.9),
              ),
              const SizedBox(height: 12),
              const Text(
                'Belum ada history aktivitas',
                style: TextStyle(
                  color: ZenColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Tambahkan aktivitas pertama kamu dari tombol + di bawah.',
                style: TextStyle(color: ZenColors.text.withValues(alpha: 0.72)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
