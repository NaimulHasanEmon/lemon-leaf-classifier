// lib/core/constants.dart
//
// App-wide constants: class labels, asset paths, and UI strings that are
// NOT localised (technical identifiers only).
//
// IMPORTANT:
//   - Class labels are ordered to match the ONNX model output index (0–4).
//   - Threshold values, metric values, and model accuracy figures are
//     intentionally ABSENT here — they must be loaded from JSON assets.

/// Fixed class names exactly as the model was trained.
/// Index must match the model's output logit index.
const List<String> kClassLabels = [
  'citrus_huanglongbing',  // index 0
  'citrus_leaf_curl',      // index 1
  'citrus_leafminer',      // index 2
  'healthy_lemon_leaf',    // index 3
  'swallowtail_herbivory', // index 4
];

/// Human-readable display names (English).
const Map<String, String> kClassDisplayNames = {
  'citrus_huanglongbing': 'Citrus Huanglongbing (HLB)',
  'citrus_leaf_curl': 'Citrus Leaf Curl',
  'citrus_leafminer': 'Citrus Leafminer',
  'healthy_lemon_leaf': 'Healthy Lemon Leaf',
  'swallowtail_herbivory': 'Swallowtail Herbivory',
};

/// Human-readable display names (Bangla).
const Map<String, String> kClassDisplayNamesBn = {
  'citrus_huanglongbing': 'সাইট্রাস হুয়াংলংবিং (HLB)',
  'citrus_leaf_curl': 'সাইট্রাস লিফ কার্ল',
  'citrus_leafminer': 'সাইট্রাস লিফমাইনার',
  'healthy_lemon_leaf': 'সুস্থ লেবু পাতা',
  'swallowtail_herbivory': 'সোয়ালোটেইল পোকার ক্ষতি',
};

// ─── Asset paths ──────────────────────────────────────────────────────────────

/// Path to the ONNX model inside the Flutter asset bundle.
/// FP32 is the deployed model artifact. The FP16 export is not used by
/// the application runtime.
const String kModelAssetPath = 'assets/models/convnext_tiny_320_f2_fp32.onnx';

/// Path to the model card JSON (accuracy metrics, norm stats, tau, delta).
const String kModelCardAssetPath = 'assets/config/model_card.json';

/// Path to the quality-gate thresholds JSON.
const String kThresholdsAssetPath = 'assets/config/thresholds.json';

/// Path to the parity test golden logits JSON.
const String kParityGoldenAssetPath = 'assets/parity/golden_logits.json';

// ─── ONNX input dimensions ────────────────────────────────────────────────────

/// Final model input size (pixels).
const int kModelInputSize = 320;

/// Intermediate size used for quality gate metrics computation.
const int kQualityGateSize = 384;

/// Intermediate stepwise-halving cap (used in preprocessing step 3).
const int kStepwiseHalvingThreshold = 512;
const int kStepwiseHalvingTargetMax = 1024;

// ─── Persistence ─────────────────────────────────────────────────────────────

/// SQLite database file name.
const String kDbFileName = 'lemon_history.db';

/// SQLite table name for history entries.
const String kHistoryTable = 'history';

// ─── SharedPreferences keys ───────────────────────────────────────────────────
const String kPrefLanguageCode = 'language_code';
const String kPrefFirstLaunchDone = 'first_launch_done';

// ─── HLB identifier (triggers extra caution text) ────────────────────────────
const String kHlbClassLabel = 'citrus_huanglongbing';
