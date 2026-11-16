# ONNX model asset

The Android application is configured to load this file:

`convnext_tiny_320_f2_fp32.onnx`

The model binary is intentionally not committed to the Git repository because it
is larger than GitHub's 100 MiB ordinary Git file limit. Download the matching
FP32 ONNX file from the repository's GitHub Release assets and place it in this
directory before running Flutter tests or building the application.

Expected SHA-256:

`241093e55054014b0da756f68ad174eeb2958bb4035701d23e08ee49b019d521`

Verify the downloaded file in PowerShell:

```powershell
(Get-FileHash .\assets\models\convnext_tiny_320_f2_fp32.onnx -Algorithm SHA256).Hash
```

The result must match the SHA-256 value above. Do not substitute the FP16 export.
