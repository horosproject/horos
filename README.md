## Build instructions

### Prerequisites

1. `cmake` and `pkg-config` must be in the system's `PATH`.
2. Patience and coffee. A full build takes about 30-45 minutes.

### Build

1. Clone the repository: `git clone https://github.com/horosproject/horos.git`

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
