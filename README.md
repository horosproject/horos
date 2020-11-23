## Build instructions

### Prerequisites

1. Must use XCode 11.3.1, due to runtime errors this will NOT work with versions above.  You can download this here: https://developer.apple.com/download/more/?q=xcode (requires being signed in to your developer account to view)
2. In XCode 11.3.1, set your command line tools to 12.1 or higher (This prevents OpenSSL from complaining during compilation with linker errors).  You can do this in XCode by going to preferences -> locations and setting the command line tool version.
3. `cmake` and `pkg-config` must be in the system's `PATH`.
4. `git-lfs` must be in the installed (for VTK-m) (https://git-lfs.github.com/) 
5. Patience and coffee. A full build takes about 30-45 minutes.

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
