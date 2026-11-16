// lib/ui/widgets/confidence_bar.dart
import 'package:flutter/material.dart';

class ConfidenceBar extends StatelessWidget {
  final String label;
  final double probability;
  final bool isTop1;
  final bool isHealthy;

  const ConfidenceBar({
    super.key,
    required this.label,
    required this.probability,
    this.isTop1 = false,
    this.isHealthy = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (probability * 100).clamp(0.0, 100.0);

    Color barColor;
    if (isHealthy) {
      barColor = Colors.green.shade600;
    } else if (isTop1) {
      barColor = theme.colorScheme.primary;
    } else {
      barColor = theme.colorScheme.outlineVariant;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isTop1 ? 14 : 13,
                    fontWeight: isTop1 ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${percent.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: isTop1 ? 14 : 13,
                  fontWeight: isTop1 ? FontWeight.bold : FontWeight.w500,
                  color: isTop1 ? barColor : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: probability.clamp(0.0, 1.0),
              minHeight: isTop1 ? 10 : 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}

