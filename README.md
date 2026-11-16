# Lemon Leaf Classifier 🌿🍃

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![ONNX Runtime](https://img.shields.io/badge/ONNX_Runtime-005CED?style=for-the-badge&logo=onnx&logoColor=white)](https://onnxruntime.ai/)
[![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com/)

[![Latest Release](https://img.shields.io/github/v/release/NaimulHasanEmon/lemon-leaf-classifier?style=flat-square)](https://github.com/NaimulHasanEmon/lemon-leaf-classifier/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/NaimulHasanEmon/lemon-leaf-classifier/total?style=flat-square)](https://github.com/NaimulHasanEmon/lemon-leaf-classifier/releases)

An offline Flutter Android research-prototype app for classifying five lemon-leaf conditions using a ConvNeXt-Tiny 320 FP32 ONNX model.

## Download the App

**Latest Android release:** [Download Lemon Leaf Classifier APK](https://github.com/NaimulHasanEmon/lemon-leaf-classifier/releases/latest)

1. Download `app-release.apk` from the latest release.
2. Transfer the APK to your Android device if necessary.
3. Open the APK and allow installation from the requested source if prompted.
4. Complete installation and launch the application.

See [GitHub Releases](https://github.com/NaimulHasanEmon/lemon-leaf-classifier/releases) for available versions.

## Important Scope and Limitations

- Intended for a single lemon leaf photographed on a plain white sheet under even lighting.
- The model failed external validation on images from different sources. It must not be presented as a field-ready diagnostic tool.
- Predictions are educational research outputs, not treatment advice.
- Raw softmax scores are shown without temperature scaling and are not calibrated probabilities of correctness.
- Huanglongbing (HLB) requires laboratory confirmation (e.g., PCR).

See `assets/config/model_card.json` for the model card and validation caveats.

## Model File

The ONNX binary is distributed separately as a GitHub Release asset because it exceeds GitHub's 100 MiB ordinary Git file limit.

For local development and rebuilding:

1. Download `convnext_tiny_320_f2_fp32.onnx` from the matching repository release.
2. Place it at `assets/models/convnext_tiny_320_f2_fp32.onnx`.
3. Verify its SHA-256 against `assets/models/README.md`.

Do not use an FP16 substitute. The app's configured model path is FP32.

## Technology Stack

- **Framework:** Flutter
- **Programming language:** Dart
- **Inference runtime:** ONNX Runtime
- **Platform:** Android
- **Model architecture:** ConvNeXt-Tiny (320 × 320, FP32, ONNX)

## Requirements

- Flutter SDK compatible with the Dart constraint in `pubspec.yaml`
- Android SDK (compile SDK 36)
- Android device or emulator meeting the app's minimum Android API level

## Local Setup

Clone the repository:

```bash
git clone https://github.com/NaimulHasanEmon/lemon-leaf-classifier.git
cd lemon-leaf-classifier
```

Download and place the required ONNX model as described in the Model File section.

Install dependencies:

```bash
flutter pub get
```

Run tests and static analysis:

```bash
flutter test
flutter analyze
```

Build the Android release APK:

```bash
flutter build apk --release
```

The model file must be downloaded before running tests or building because it is a declared Flutter asset.

## Project Structure

- `lib/` — Flutter application source
- `android/` — Android platform configuration
- `assets/config/` — Model card, thresholds, and evaluation metadata
- `assets/parity/` — Parity images and golden reference logits
- `assets/models/` — Downloaded ONNX model (not committed)
- `test/` — Automated tests
- `tools/` — Development utilities

## Releases

Prebuilt Android APKs are available through [GitHub Releases](https://github.com/NaimulHasanEmon/lemon-leaf-classifier/releases).

The source code is available in this repository. The APK is provided for convenient installation and evaluation.

## Licensing

Third-party model, pretrained-weight, dataset, and runtime terms must be reviewed before redistribution. Add the app's chosen software license and any required dataset/model attributions before public release. No license is granted by this README.
