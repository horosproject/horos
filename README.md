## Build instructions

### Prerequisites

1. `cmake` and `pkg-config` must be in the system's `PATH` or installed at `/opt/local/bin` (Intel) or `/opt/homebrew/bin` (Apple Silicon).
3. `git-lfs` must be in the installed (for VTK-m) (https://git-lfs.github.com/) 
4. Patience or a fast Mac, a full build takes from 5 minutes to 30 minutes.

### Build

1. Clone the repository: `git clone https://github.com/frnext/horos.git`

### Option 1 (GUI)

1. Open `Horos.xcodeproj` in Xcode
2. Build (Command+B)

### Option 2 (terminal)

1. Go to the project root directory
2. `make` (or `make ADHOC=1` to sign ad-hoc if you're not a member of the project's development team, `make CONFIG=Release` for a release build)

The Makefile sets `CMAKE_POLICY_VERSION_MINIMUM=3.5`, which CMake 4 needs to configure some submodules.
When building from Xcode with CMake 4, set that variable in your environment first (e.g. `launchctl setenv CMAKE_POLICY_VERSION_MINIMUM 3.5`).

## Additional remarks

The project uses git submodules and depends on files that are in a zipped format.
The build process takes care of these dependencies, but you can invoke the steps manually:

- To unzip the binaries, you can build the target `Unzip Binaries`
- To initialize the submodules: `git submodule update --init --recursive`

### Building on macOS 26 / Xcode 26

Tested with macOS 26.5, Xcode 26.6, CMake 4 and Homebrew on Apple Silicon (`brew install cmake pkg-config git-lfs libtiff little-cms2 libpng`).
The following adjustments make the build work with this toolchain:

- **Third-party build scripts** (`Horos/Scripts/<Lib>/`):
  - Grok, OpenJPEG: the codec executables link `-ltiff`/`-llcms2`/`-lpng` without the Homebrew library dirs; these are now added via `pkg-config`.
  - OpenJPEG: `BUILD_THIRDPARTY=OFF`, as its bundled zlib doesn't compile with recent SDKs (`fdopen` macro); ITK now uses the SDK's zlib (`ITK_USE_SYSTEM_ZLIB=ON`), like VTK.
  - VTK, ITK: bundled libpng includes the Classic Mac OS `<fp.h>` when `TARGET_OS_MAC` is defined; C files are now compiled with `-include math.h`, which skips it.
  - VTK (bundled Eigen 3.3) and DCMTK 3.6.7 (`ofutil.h`) contain template code rejected by clang >= 19; the scripts patch those lines in the submodules before configuring.
  - GDCM looks for the OpenJPEG headers in `include/OpenJPEG`, where the OpenJPEG script installs them; Grok only copies `libopenjp2.a` if `make install` didn't.
  - OpenSSL: macOS' `rsync` (openrsync) fails intermittently under `xcodebuild` (exit code 20); the script falls back to `ditto`.
- **App**:
  - App Sandbox is disabled (`ENABLE_APP_SANDBOX = NO`): Horos isn't designed for it, and it blocked the DICOM Listener and file access.
  - `UIDesignRequiresCompatibility` in `Info.plist` keeps the pre-macOS 26 look.
  - `API.sh` copies `Horos.framework` under legacy names for old plugins and edits their `Info.plist`, which broke the app's code signature (macOS then reports the app as damaged); the copies are now re-signed with the app's identity.
  - Toolbar icons are large PDFs, which AppKit no longer scales down to the toolbar size when linked against the macOS 26 SDK; `NSToolbarItem -setImage:` is swizzled in `AppController.m` to scale them to 32×32.
  - Windows no longer use the deprecated textured style (`texturedBackground` removed from the XIBs' `styleMask`, along with their manual `contentBorderThickness`, which ibtool rejects on regular windows). On macOS 27, AppKit throws an exception in `-[NSWindow _postWindowNeedsDisplay]` when a textured window's toolbar contains an `NSSlider` (e.g. the viewer's cine sliders), which crashed Horos when opening images.
  - The 3D MPR viewer renders through a hidden `VRView` that is never drawn, so its VTK render window (and GLEW, whose function pointers stay NULL) was never initialized: `-[VRView render]` now initializes it first, as `-[VTKView drawRect:]` does.
  - Endoscopy: the outer split view in `Endoscopy.xib` used Auto Layout around autoresizing subviews, and macOS 27 throws when the layout pass resizes the image views (`setNeedsUpdateConstraints` during layout); it now uses autoresizing, like the MPR window. Closing the window also crashed: `EndoscopyVRController` never observes the shadings controller, which is released with its nib, so it clears that outlet before `-[VRController dealloc]` removes the observer.

For more information on this code, visit [horosproject.org](https://horosproject.org/get-involved/)
