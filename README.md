# Lemon Leaf Classifier

An offline Flutter Android research-prototype app for classifying five lemon-leaf
conditions using a ConvNeXt-Tiny 320 FP32 ONNX model.

## Important scope and limitations

- Intended for a single lemon leaf photographed on a plain white sheet under
  even lighting.
- The model failed external validation on images from different sources.
  It must not be presented as a field-ready diagnostic tool.
- Predictions are educational research outputs, not treatment advice.
- Raw softmax scores are shown without temperature scaling and are not
  calibrated probabilities of correctness.
- Huanglongbing (HLB) requires laboratory confirmation (e.g., PCR).

See `assets/config/model_card.json` for the model card and validation caveats.

## Model file

The ONNX binary is distributed separately as a GitHub Release asset because
it exceeds GitHub's 100 MiB ordinary Git file limit.

1. Download `convnext_tiny_320_f2_fp32.onnx` from the matching repository
   release.
2. Place it at `assets/models/convnext_tiny_320_f2_fp32.onnx`.
3. Verify its SHA-256 against `assets/models/README.md`.

Do not use an FP16 substitute. The app's configured model path is FP32.

## Requirements

- Flutter SDK compatible with the Dart constraint in `pubspec.yaml`
- Android SDK (compile SDK 36)
- Android device or emulator meeting the app's minimum Android API level

## Local setup

```bash
flutter pub get
flutter test
flutter analyze
flutter build apk --release
```

The model file must be downloaded before running tests or building because it is
a declared Flutter asset.

## Project structure

- `lib/` — Flutter application source
- `android/` — Android platform configuration
- `assets/config/` — model card, thresholds, evaluation metadata
- `assets/parity/` — parity images and golden reference logits
- `assets/models/` — downloaded ONNX model (not committed)
- `test/` — automated tests
- `tools/` — development utilities

## Licensing

Third-party model, pretrained-weight, dataset, and runtime terms must be reviewed
before redistribution. Add the app's chosen software license and any required
dataset/model attributions before public release. No license is granted by this
README.
