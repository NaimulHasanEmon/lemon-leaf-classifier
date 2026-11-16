# Pre-upload audit and remaining checks

## Corrections made in this source package

- Removed the machine-specific `android/local.properties`.
- Kept the app's model path on the FP32 ONNX artifact.
- Updated the model card's deployed-model identity and SHA-256 to FP32, matching
  `assets/config/eval_results.json`.
- Marked the FP16 export as not deployed.
- Replaced tests that referenced removed APIs/constants with tests for the
  implementation that is actually present.
- Extracted the production softmax calculation into a shared utility so tests
  exercise the same function used by inference.
- Updated the parity asset test: the ONNX binary is a GitHub Release asset, not
  a file expected inside the Git repository.
- Removed unused imports/variables and updated deprecated `withOpacity` calls.
- Added `assets/models/README.md` with the expected model filename and hash.
- Updated the root README with scope, external-validation limitations, model
  download steps, and build instructions.

## Checks completed during this ZIP audit

- ZIP integrity: passed.
- JSON syntax for model/config files: passed.
- 100 parity PNG files present.
- `android/local.properties` removed from this source package.
- No obvious API-key, password, private-key, or machine-specific Windows path
  patterns found in the reviewed text files.
- FP32 model SHA in the model card matches the SHA recorded in evaluation JSON.

## Checks not performed here

This environment does not have Flutter/Dart or an Android device, and the ONNX
binary was intentionally excluded from the uploaded ZIP. Therefore this audit
does NOT claim that `flutter analyze`, `flutter test`, APK compilation, or
on-device inference has passed.

## Before making the repository public

1. Keep your local FP32 model file at
   `assets/models/convnext_tiny_320_f2_fp32.onnx`. Do not commit it.
2. Verify the model file's SHA-256 against `assets/models/README.md`.
3. Upload that exact model file as a GitHub Release asset.
4. Confirm you have redistribution rights for the 100 parity PNGs and all
   third-party model/runtime assets.
5. Add an explicit software license after deciding the intended license.
6. On Windows, run `flutter pub get`, `flutter analyze`, `flutter test`, and
   `flutter build apk --release`.
7. Install and test the release APK on the target Android phone, including
   camera/gallery input, quality rejection, accepted/abstained predictions,
   history, and offline operation.
8. Review the release signing configuration before distributing a production
   APK. The current Gradle file uses the debug signing key for the release
   build; that is not suitable for a Play Store production release.
