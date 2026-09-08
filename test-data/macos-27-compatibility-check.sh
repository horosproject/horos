#!/bin/bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

window_xibs=(
    Horos/Resources/en.lproj/Viewer.xib
    Horos/Resources/ja-JP.lproj/Viewer.xib
    Horos/Resources/en.lproj/SR.xib
    Horos/Resources/ja-JP.lproj/SR.xib
    Horos/Resources/en.lproj/Endoscopy.xib
    Horos/Resources/ja-JP.lproj/Endoscopy.xib
    Horos/Resources/en.lproj/CPR.xib
    Horos/Resources/ja-JP.lproj/CPR.xib
    Horos/Resources/en.lproj/MPR.xib
    Horos/Resources/ja-JP.lproj/MPR.xib
    Horos/Resources/en.lproj/OrthogonalMPR.xib
    Horos/Resources/ja-JP.lproj/OrthogonalMPR.xib
    Horos/Resources/en.lproj/VR.xib
    Horos/Resources/ja-JP.lproj/VR.xib
    Horos/Resources/en.lproj/PETCT.xib
    Horos/Resources/ja-JP.lproj/PETCT.xib
)

for relative_path in "${window_xibs[@]}"; do
    xib="$repo_root/$relative_path"
    xmllint --noout "$xib"

    if grep -q 'texturedBackground="YES"' "$xib"; then
        echo "error: textured window style is forbidden in $relative_path" >&2
        exit 1
    fi
done

viewer_controller="$repo_root/Horos/Sources/ViewerController.m"
if grep -E -q 'setImage: *\[NSImage imageNamed: *(Play|Pause)ToolbarItemIdentifier\]' "$viewer_controller"; then
    echo "error: cine Play/Pause images must pass through toolbarSizedImage:" >&2
    exit 1
fi

# Initialization belongs at the shared rendering boundary, so every caller is safe.
for method in render renderBlendedVolume; do
    body="$(LC_ALL=C sed -n "/^- (void) $method\$/,/^}/p" "$repo_root/Horos/Sources/VRView.mm")"
    if ! awk '
        /\[self initializeVTKRenderWindowIfNeeded\];/ { initialized = 1 }
        /->Render\(/ { renders++; if (!initialized) failed = 1 }
        END { exit (failed || renders != 1) }
    ' <<< "$body"; then
        echo "error: VRView $method must initialize VTK before the mapper renders" >&2
        exit 1
    fi
done

app_controller="$repo_root/Horos/Sources/AppController.m"
if grep -q 'Error = GetAllPIDsForProcessName(' "$app_controller"; then
    echo "error: startup cleanup must not use the blocking KERN_PROC_ALL process scan" >&2
    exit 1
fi

browser_controller="$repo_root/Horos/Sources/BrowserController.m"
browser_toolbar_delegate="$(LC_ALL=C sed -n '/^- (NSToolbarItem \*) toolbar:/,/^}$/p' "$browser_controller")"
if ! grep -q 'toolbarItem = nil;' <<< "$browser_toolbar_delegate"; then
    echo "error: unavailable saved plugin toolbar items must be discarded" >&2
    exit 1
fi

echo "macOS 27 compatibility checks passed"
