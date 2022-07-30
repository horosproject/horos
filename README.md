## Build instructions

### Prerequisites

1. `cmake` and `pkg-config` must be in the system's `PATH` or installed at `/opt/local/bin`.
2. `git-lfs` must be in the installed (for VTK-m) (https://git-lfs.github.com/) 
3. Patience or a fast Mac, a full build takes from 5 minutes to 30 minutes.

### Build

1. Clone the repository: `git clone https://github.com/frnext/horos.git`

### Option 1 (GUI)

1. Open `Horos.xcodeproj` in Xcode
2. Build (Command+B)

### Option 2 (terminal)

1. Go to the project root directory
2. `make`

## Additional remarks

The project uses git submodules and depends on files that are in a zipped format.
The build process takes care of these dependencies, but you can invoke the steps manually:

- To unzip the binaries, you can build the target `Unzip Binaries`
- To initialize the submodules: `git submodule update --init --recursive`

For more information on this code, visit [horosproject.org](https://horosproject.org/get-involved/)
