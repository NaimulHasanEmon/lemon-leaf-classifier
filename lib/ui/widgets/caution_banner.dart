// lib/ui/widgets/caution_banner.dart
import 'package:flutter/material.dart';

class CautionBanner extends StatelessWidget {
  final bool isHlb;

  const CautionBanner({
    super.key,
    this.isHlb = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHlb ? Colors.red.shade50 : Colors.amber.shade50,
        border: Border.all(
          color: isHlb ? Colors.red.shade400 : Colors.amber.shade600,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isHlb ? Icons.report_problem_rounded : Icons.info_outline_rounded,
                color: isHlb ? Colors.red.shade800 : Colors.amber.shade900,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isHlb ? 'CRITICAL PATHOLOGY NOTICE (HLB)' : 'RESEARCH PROTOTYPE ADVISORY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isHlb ? Colors.red.shade900 : Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isHlb
                ? 'Huanglongbing (HLB / Citrus Greening) is a catastrophic citrus disease. Symptoms mimic zinc/iron deficiency. Definitive diagnosis requires qPCR molecular testing by certified agricultural laboratories. Do not eradicate or spray solely based on this app.'
                : 'Confidence is not a probability of correctness under different lighting or backgrounds. Symptoms overlap across conditions. Use on plain white sheets only.',
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: isHlb ? Colors.red.shade900 : Colors.brown.shade900,
            ),
          ),
        ],
      ),
    );
  }
}

