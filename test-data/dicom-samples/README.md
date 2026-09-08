# Horos DICOM smoke-test set

Small fixtures for checking Horos import, display, multiframe navigation, and
compressed-pixel decoding. They are not large enough to reproduce database or
3D-rendering performance problems by themselves.

| File | Coverage | Transfer syntax | Image shape |
| --- | --- | --- | --- |
| `CT_small.dcm` | Basic CT | Explicit VR Little Endian | 128 x 128, 1 frame |
| `MR_small.dcm` | Basic MR | Explicit VR Little Endian | 64 x 64, 1 frame |
| `MR_small_RLE.dcm` | Compressed MR | RLE Lossless | 64 x 64, 1 frame |
| `MR_small_jp2klossless.dcm` | Compressed MR | JPEG 2000 Lossless | 64 x 64, 1 frame |
| `SC_rgb_rle_2frame.dcm` | RGB Secondary Capture and multiframe | RLE Lossless | 100 x 100 RGB, 2 frames |
| `US1_J2KI.dcm` | Color ultrasound | JPEG 2000 Lossy | 640 x 480 YBR, 1 frame |
| `eCT_Supplemental.dcm` | Enhanced CT, multiframe, supplemental palette LUT | Explicit VR Little Endian | 512 x 512, 2 frames |

## Suggested Horos test

Use a disposable Horos database, then import each file and confirm that it
opens, renders correctly, and does not crash while changing window/level and
scrolling multiframe images.

`MR_small.dcm`, `MR_small_RLE.dcm`, and `MR_small_jp2klossless.dcm` intentionally
carry the same Study, Series, and SOP Instance UIDs. Horos may treat them as the
same database object, so import only one of those three per clean test database
when comparing transfer syntaxes.

These fixtures contain test-looking patient fields, but the upstream project
does not claim formal clinical-grade de-identification. Keep them in an
isolated test database and do not mix them with clinical data.

## Provenance

The first five files are pinned to pydicom commit
[`0e98c4aeecce7c3ae537e3fbe9133d3fbc005796`](https://github.com/pydicom/pydicom/tree/0e98c4aeecce7c3ae537e3fbe9133d3fbc005796/src/pydicom/data/test_files).
The last two are pinned to pydicom-data commit
[`abc42b90985fb6cf385aa4af766d2c9c94a257a4`](https://github.com/pydicom/pydicom-data/tree/abc42b90985fb6cf385aa4af766d2c9c94a257a4/data_store/data).

The upstream [test-file notes](https://github.com/pydicom/pydicom/blob/0e98c4aeecce7c3ae537e3fbe9133d3fbc005796/src/pydicom/data/test_files/README.txt)
describe the files as downsized test images and say that apparent real patient
names were replaced in some cases. Repository licenses are
[pydicom](https://github.com/pydicom/pydicom/blob/0e98c4aeecce7c3ae537e3fbe9133d3fbc005796/LICENSE)
and [pydicom-data](https://github.com/pydicom/pydicom-data/blob/abc42b90985fb6cf385aa4af766d2c9c94a257a4/LICENSE).

## Integrity

Download the pinned fixtures and verify their hashes with:

```sh
cd test-data/dicom-samples
./download.sh
```

All seven files were parsed and their complete pixel arrays decoded with
pydicom plus the pylibjpeg-openjpeg decoder during the macOS 27 investigation.
