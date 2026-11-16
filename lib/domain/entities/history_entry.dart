// lib/domain/entities/history_entry.dart
import 'dart:typed_data';

class HistoryEntry {
  final int? id;
  final DateTime timestamp;
  final String? imagePath;
  final Uint8List? thumbnailBytes;
  final String status;
  final String? predictedClass;
  final double? probability;
  final String? failureReason;

  const HistoryEntry({
    this.id,
    required this.timestamp,
    this.imagePath,
    this.thumbnailBytes,
    required this.status,
    this.predictedClass,
    this.probability,
    this.failureReason,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'image_path': imagePath,
      'thumbnail_bytes': thumbnailBytes,
      'status': status,
      'predicted_class': predictedClass,
      'probability': probability,
      'failure_reason': failureReason,
    };
  }

  factory HistoryEntry.fromMap(Map<String, dynamic> map) {
    return HistoryEntry(
      id: map['id'] as int?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      imagePath: map['image_path'] as String?,
      thumbnailBytes: map['thumbnail_bytes'] as Uint8List?,
      status: map['status'] as String,
      predictedClass: map['predicted_class'] as String?,
      probability: map['probability'] != null ? (map['probability'] as num).toDouble() : null,
      failureReason: map['failure_reason'] as String?,
    );
  }
}

