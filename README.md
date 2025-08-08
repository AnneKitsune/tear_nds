# Zig Nintendo DS

Provides an easy and convenient way to compile for nds and use functions from [DevKitPro](https://devkitpro.org/).

1. Install zig 0.14 / 0.15.
2. `nix develop`
4. zig build # creates a .nds file
5. zig build run # runs the .nds file in the `melonDS` emulator

The .nds file will be in zig-out/bin/name.nds.

### Adding NDS support to your project

build.zig
```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    // So that you can call exported functions from anne_nds_dev
    const anne_nds_dev = b.dependency("anne_nds_dev", .{}).module("anne_nds_dev");
    // Creates the module + obj + elf + nds files for you and takes care of the includes/linker arguments.
    const nds_step = @import("anne_nds_dev").compileNds(b, .{
        .root_file = b.path("src/main.zig"),
        .optimize = optimize,
        .name = "nds_test",
        .imports = &.{
            .{
                .name = "nds",
                .module = anne_nds_dev,
            },
        },
    });

    // `zig build` will build for nds.
    b.default_step.dependOn(&nds_step.step);
}
```

src/main.zig
```zig
const nds = @import("nds").nds;
// You need to export a c-style main. Then inside of the main you can call nds' functions.
export fn main(_: c_int, _: [*]const [*:0]const u8) void {...}
```

### Going further
The documentation for libnds, which is what actually does the heavy lifting of communicating with the DS, is available here: https://libnds.devkitpro.org/files.html
Several examples are available here: https://github.com/devkitPro/nds-examples

### Credits
This work is based on [DevKitPro](https://devkitpro.org/), [devkitNix](https://github.com/bandithedoge/devkitNix) and [zig-nds](https://github.com/zig-homebrew/zig-nds).
