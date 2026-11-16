// lib/domain/entities/thresholds_info.dart

class MetricBounds {
  final double? lower;
  final double? upper;

  const MetricBounds({this.lower, this.upper});

  factory MetricBounds.fromJson(Map<String, dynamic> json) {
    return MetricBounds(
      lower: json['lower'] != null ? (json['lower'] as num).toDouble() : null,
      upper: json['upper'] != null ? (json['upper'] as num).toDouble() : null,
    );
  }
}

class ThresholdsInfo {
  final String description;
  final String imagesUsed;
  final MetricBounds sharpness;
  final MetricBounds exposure;
  final MetricBounds borderBrightness;
  final MetricBounds saturation;

  const ThresholdsInfo({
    required this.description,
    required this.imagesUsed,
    required this.sharpness,
    required this.exposure,
    required this.borderBrightness,
    required this.saturation,
  });

  factory ThresholdsInfo.fromJson(Map<String, dynamic> json) {
    final gate = json['gate'] as Map<String, dynamic>;
    return ThresholdsInfo(
      description: json['description'] ?? '',
      imagesUsed: json['images_used'] ?? '',
      sharpness: MetricBounds.fromJson(gate['sharpness'] as Map<String, dynamic>),
      exposure: MetricBounds.fromJson(gate['exposure'] as Map<String, dynamic>),
      borderBrightness: MetricBounds.fromJson(gate['border_brightness'] as Map<String, dynamic>),
      saturation: MetricBounds.fromJson(gate['saturation'] as Map<String, dynamic>),
    );
  }
}

