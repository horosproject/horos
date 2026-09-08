# macOS 27 field test: 4.0.2 (20260908)

This is an Apple Silicon test build for reproducing viewer compatibility issues.
It is not a production validation of all Horos workflows.

## Changes

- Initialize VTK at the shared VRView render/renderBlendedVolume boundary before
  direct mapper calls, covering Curved MPR as well as regular MPR callers.
- Remove the deprecated textured-window style from CPR, Surface Rendering,
  Endoscopy and 2D Viewer resources in English and Japanese.
- Track and retain the shading controller actually observed by VRController.
  Embedded Endoscopy controllers bypass that observer registration; teardown
  must not message their unretained nib outlet to remove an unregistered observer.
- Ignore unchanged DCMView frames to avoid redundant constraint invalidations.
  This guard targets an AppKit split-view layout loop and still needs field verification.

## Local evidence

On macOS 27.0 (26A5425a), arm64, the previous compatibility build crashed while
opening Curved MPR on the synthetic Test Repro CT series (30 x 512 x 512).
The top frames lead through vtkShader::Compile and a null glCreateShader pointer.
With the shared initialization fix, Curved MPR opens and reconstructs a drawn
path; stretched/high-resolution and Mean modes were exercised. Regular MPR,
orthogonal MPR, MIP Best, CPU/GPU volume rendering, surface rendering and
Endoscopy also rendered the fixture. CPR, VR, surface and Endoscopy were checked
with external plugins disabled.

Further open/close checks found AppKit constraint-loop exceptions and an
Endoscopy-close crash in VRController's observer removal. The subsequent fixes
build successfully and pass the static compatibility checks, but their complete
runtime rerun was blocked by the rebuilt app's macOS Documents-access prompt.
Earlier rendering screenshots do not prove these later lifecycle fixes.

Commands:

```sh
xcodebuild -project Horos.xcodeproj -target 'Unzip Binaries' -configuration Release CODE_SIGNING_ALLOWED=NO
xcodebuild -project Horos.xcodeproj -scheme Horos -configuration Release -derivedDataPath /tmp/horos-cpr-build CODE_SIGNING_ALLOWED=NO ARCHS=arm64 ONLY_ACTIVE_ARCH=YES
bash test-data/macos-27-compatibility-check.sh
git diff --check
```

## Reviewer / Dr Yu checklist

1. Quit Horos. Back up the active Horos Data folder and keep the previous app.
2. Install the supplied test app; allow macOS folder access if prompted.
3. Start with synthetic/public DICOM data, then a copied/anonymized failing series.
4. Open Curved MPR; draw a path; switch Straightened/Stretched, Standard/High-Res,
   MIP/Mean; close and reopen repeatedly.
5. Open, render, close and reopen regular/orthogonal MPR, MIP, volume rendering,
   surface rendering and Endoscopy. Exercise VR shading controls as well.
6. Record viewer, series size, exact action and time for any failure; retain the
   Horos crash report from Console or Library/Logs/DiagnosticReports.

Fusion/PETCT, stereo, exports, Japanese runtime, Intel and older macOS have not
been verified in this run. The field-test package disables plugin loading with
Contents/PlugIns/DoNotLoad.txt containing `*`, to isolate the app fixes from the
installed TahoeWindowFix workaround. Source plugin-loading behavior is unchanged.
The two app versions share the same preferences and database; app rollback alone
does not restore the database.
