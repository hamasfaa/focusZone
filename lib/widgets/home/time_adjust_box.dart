import 'package:flutter/material.dart';
import 'package:mini_project/theme/zen_colors.dart';

class TimeAdjustBox extends StatelessWidget {
  const TimeAdjustBox({
    super.key,
    required this.label,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
  });

  final String label;
  final int value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: ZenColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ZenColors.accent, width: 1.1),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: ZenColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          IconButton(
            onPressed: onIncrement,
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: ZenColors.secondary,
            visualDensity: VisualDensity.compact,
            splashRadius: 20,
          ),
          Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: ZenColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          IconButton(
            onPressed: onDecrement,
            icon: const Icon(Icons.remove_circle_outline_rounded),
            color: ZenColors.secondary,
            visualDensity: VisualDensity.compact,
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}
