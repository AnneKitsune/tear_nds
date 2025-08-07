# Zig Nintendo DS

Provides an easy and convenient way to compile for nds and use functions from [DevKitPro](https://devkitpro.org/).

1. Install zig 0.14 / 0.15.
2. `nix develop`.
3. ./setup.sh
4. zig build
5. zig build run (to run in an emulator)

The .nds file will be in zig-out/name.nds.

### Going further
The documentation for libnds, which is what actually does the heavy lifting of communicating with the DS, is available here: https://libnds.devkitpro.org/files.html
Several examples are available here: https://github.com/devkitPro/nds-examples

### Credits
This work is based on [DevKitPro](https://devkitpro.org/), [devkitNix](https://github.com/bandithedoge/devkitNix) and [zig-nds](https://github.com/zig-homebrew/zig-nds).
