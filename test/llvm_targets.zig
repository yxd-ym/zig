const std = @import("std");
const Cases = @import("src/Cases.zig");

const targets = [_]std.Target.Query{
    .{ .cpu_arch = .aarch64, .os_tag = .bridgeos, .abi = .none },
    .{ .cpu_arch = .aarch64, .os_tag = .driverkit, .abi = .none },
    .{ .cpu_arch = .aarch64, .os_tag = .freebsd, .abi = .none },
    .{ .cpu_arch = .aarch64, .os_tag = .freestanding, .abi = .none },
    .{ .cpu_arch = .aarch64, .os_tag = .fuchsia, .abi = .none },
    .{ .cpu_arch = .aarch64, .os_tag = .haiku, .abi = .none },
    .{ .cpu_arch = .aarch64, .os_tag = .hermit, .abi = .none },
    .{ .cpu_arch = .aarch64, .os_tag = .hurd, .abi = .gnu },
    .{ .cpu_arch = .aarch64, .os_tag = .ios, .abi = .macabi },
    .{ .cpu_arch = .aarch64, .os_tag = .ios, .abi = .none },
    .{ .cpu_arch = .aarch64, .os_tag = .ios, .abi = .simulator },
    .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .android },
    .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .gnuilp32 },
    .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .none },
    .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .ohos },
    .{ .cpu_arch = .aarch64, .os_tag = .macos, .abi = .none },
    .{ .cpu_arch = .aarch64, .os_tag = .netbsd, .abi = .none },
    .{ .cpu_arch = .aarch64, .os_tag = .openbsd, .abi = .none },
    .{ .cpu_arch = .aarch64, .os_tag = .rtems, .abi = .ilp32 },
    .{ .cpu_arch = .aarch64, .os_tag = .rtems, .abi = .none },
    .{ .cpu_arch = .aarch64, .os_tag = .serenity, .abi = .none },
    .{ .cpu_arch = .aarch64, .os_tag = .tvos, .abi = .none },
    .{ .cpu_arch = .aarch64, .os_tag = .tvos, .abi = .simulator },
    .{ .cpu_arch = .aarch64, .os_tag = .uefi, .abi = .none },
    .{ .cpu_arch = .aarch64, .os_tag = .visionos, .abi = .none },
    .{ .cpu_arch = .aarch64, .os_tag = .visionos, .abi = .simulator },
    .{ .cpu_arch = .aarch64, .os_tag = .watchos, .abi = .ilp32 },
    .{ .cpu_arch = .aarch64, .os_tag = .watchos, .abi = .none },
    .{ .cpu_arch = .aarch64, .os_tag = .watchos, .abi = .simulator },
    .{ .cpu_arch = .aarch64, .os_tag = .windows, .abi = .gnu },
    .{ .cpu_arch = .aarch64, .os_tag = .windows, .abi = .itanium },
    .{ .cpu_arch = .aarch64, .os_tag = .windows, .abi = .msvc },

    .{ .cpu_arch = .aarch64_be, .os_tag = .freestanding, .abi = .none },
    .{ .cpu_arch = .aarch64_be, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .aarch64_be, .os_tag = .linux, .abi = .gnuilp32 },
    .{ .cpu_arch = .aarch64_be, .os_tag = .linux, .abi = .none },
    .{ .cpu_arch = .aarch64_be, .os_tag = .netbsd, .abi = .none },

    .{ .cpu_arch = .amdgcn, .os_tag = .amdhsa, .abi = .none },
    .{ .cpu_arch = .amdgcn, .os_tag = .amdpal, .abi = .none },
    .{ .cpu_arch = .amdgcn, .os_tag = .mesa3d, .abi = .none },

    .{ .cpu_arch = .arc, .os_tag = .freestanding, .abi = .none },
    .{ .cpu_arch = .arc, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .arc, .os_tag = .linux, .abi = .none },

    .{ .cpu_arch = .arm, .os_tag = .freebsd, .abi = .eabi },
    .{ .cpu_arch = .arm, .os_tag = .freebsd, .abi = .eabihf },
    .{ .cpu_arch = .arm, .os_tag = .freestanding, .abi = .eabi },
    .{ .cpu_arch = .arm, .os_tag = .freestanding, .abi = .eabihf },
    .{ .cpu_arch = .arm, .os_tag = .haiku, .abi = .eabi },
    .{ .cpu_arch = .arm, .os_tag = .haiku, .abi = .eabihf },
    .{ .cpu_arch = .arm, .os_tag = .linux, .abi = .androideabi },
    .{ .cpu_arch = .arm, .os_tag = .linux, .abi = .eabi },
    .{ .cpu_arch = .arm, .os_tag = .linux, .abi = .eabihf },
    .{ .cpu_arch = .arm, .os_tag = .linux, .abi = .gnueabi },
    .{ .cpu_arch = .arm, .os_tag = .linux, .abi = .gnueabihf },
    .{ .cpu_arch = .arm, .os_tag = .linux, .abi = .musleabi },
    .{ .cpu_arch = .arm, .os_tag = .linux, .abi = .musleabihf },
    .{ .cpu_arch = .arm, .os_tag = .linux, .abi = .ohoseabi },
    .{ .cpu_arch = .arm, .os_tag = .netbsd, .abi = .eabi },
    .{ .cpu_arch = .arm, .os_tag = .netbsd, .abi = .eabihf },
    .{ .cpu_arch = .arm, .os_tag = .openbsd, .abi = .eabi },
    .{ .cpu_arch = .arm, .os_tag = .openbsd, .abi = .eabihf },
    .{ .cpu_arch = .arm, .os_tag = .rtems, .abi = .eabi },
    .{ .cpu_arch = .arm, .os_tag = .rtems, .abi = .eabihf },
    .{ .cpu_arch = .arm, .os_tag = .uefi, .abi = .eabi },
    .{ .cpu_arch = .arm, .os_tag = .uefi, .abi = .eabihf },

    .{ .cpu_arch = .armeb, .os_tag = .freebsd, .abi = .eabi },
    .{ .cpu_arch = .armeb, .os_tag = .freebsd, .abi = .eabihf },
    .{ .cpu_arch = .armeb, .os_tag = .freestanding, .abi = .eabi },
    .{ .cpu_arch = .armeb, .os_tag = .freestanding, .abi = .eabihf },
    .{ .cpu_arch = .armeb, .os_tag = .linux, .abi = .eabi },
    .{ .cpu_arch = .armeb, .os_tag = .linux, .abi = .eabihf },
    .{ .cpu_arch = .armeb, .os_tag = .linux, .abi = .gnueabi },
    .{ .cpu_arch = .armeb, .os_tag = .linux, .abi = .gnueabihf },
    .{ .cpu_arch = .armeb, .os_tag = .linux, .abi = .musleabi },
    .{ .cpu_arch = .armeb, .os_tag = .linux, .abi = .musleabihf },
    .{ .cpu_arch = .armeb, .os_tag = .netbsd, .abi = .eabi },
    .{ .cpu_arch = .armeb, .os_tag = .netbsd, .abi = .eabihf },
    .{ .cpu_arch = .armeb, .os_tag = .rtems, .abi = .eabi },
    .{ .cpu_arch = .armeb, .os_tag = .rtems, .abi = .eabihf },

    .{ .cpu_arch = .avr, .os_tag = .freestanding, .abi = .none },
    .{ .cpu_arch = .avr, .os_tag = .rtems, .abi = .none },

    .{ .cpu_arch = .bpfeb, .os_tag = .freestanding, .abi = .none },

    .{ .cpu_arch = .bpfel, .os_tag = .freestanding, .abi = .none },

    .{ .cpu_arch = .csky, .os_tag = .freestanding, .abi = .eabi },
    .{ .cpu_arch = .csky, .os_tag = .freestanding, .abi = .eabihf },
    .{ .cpu_arch = .csky, .os_tag = .linux, .abi = .eabi },
    .{ .cpu_arch = .csky, .os_tag = .linux, .abi = .eabihf },
    .{ .cpu_arch = .csky, .os_tag = .linux, .abi = .gnueabi },
    .{ .cpu_arch = .csky, .os_tag = .linux, .abi = .gnueabihf },

    .{ .cpu_arch = .hexagon, .os_tag = .freestanding, .abi = .none },
    .{ .cpu_arch = .hexagon, .os_tag = .linux, .abi = .none },

    .{ .cpu_arch = .lanai, .os_tag = .freestanding, .abi = .none },

    .{ .cpu_arch = .loongarch32, .os_tag = .freestanding, .abi = .none },
    .{ .cpu_arch = .loongarch32, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .loongarch32, .os_tag = .linux, .abi = .gnuf32 },
    .{ .cpu_arch = .loongarch32, .os_tag = .linux, .abi = .gnusf },
    .{ .cpu_arch = .loongarch32, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .loongarch32, .os_tag = .linux, .abi = .none },
    .{ .cpu_arch = .loongarch32, .os_tag = .uefi, .abi = .none },

    .{ .cpu_arch = .loongarch64, .os_tag = .freestanding, .abi = .none },
    .{ .cpu_arch = .loongarch64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .loongarch64, .os_tag = .linux, .abi = .gnuf32 },
    .{ .cpu_arch = .loongarch64, .os_tag = .linux, .abi = .gnusf },
    .{ .cpu_arch = .loongarch64, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .loongarch64, .os_tag = .linux, .abi = .none },
    .{ .cpu_arch = .loongarch64, .os_tag = .uefi, .abi = .none },

    .{ .cpu_arch = .m68k, .os_tag = .freestanding, .abi = .none },
    .{ .cpu_arch = .m68k, .os_tag = .haiku, .abi = .none },
    .{ .cpu_arch = .m68k, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .m68k, .os_tag = .linux, .abi = .none },
    .{ .cpu_arch = .m68k, .os_tag = .netbsd, .abi = .none },
    .{ .cpu_arch = .m68k, .os_tag = .rtems, .abi = .none },

    .{ .cpu_arch = .mips, .os_tag = .freebsd, .abi = .eabi },
    .{ .cpu_arch = .mips, .os_tag = .freebsd, .abi = .eabihf },
    .{ .cpu_arch = .mips, .os_tag = .freestanding, .abi = .eabi },
    .{ .cpu_arch = .mips, .os_tag = .freestanding, .abi = .eabihf },
    .{ .cpu_arch = .mips, .os_tag = .linux, .abi = .eabi },
    .{ .cpu_arch = .mips, .os_tag = .linux, .abi = .eabihf },
    .{ .cpu_arch = .mips, .os_tag = .linux, .abi = .gnueabi },
    .{ .cpu_arch = .mips, .os_tag = .linux, .abi = .gnueabihf },
    .{ .cpu_arch = .mips, .os_tag = .linux, .abi = .musleabi },
    .{ .cpu_arch = .mips, .os_tag = .linux, .abi = .musleabihf },
    .{ .cpu_arch = .mips, .os_tag = .netbsd, .abi = .eabi },
    .{ .cpu_arch = .mips, .os_tag = .netbsd, .abi = .eabihf },
    .{ .cpu_arch = .mips, .os_tag = .rtems, .abi = .eabi },
    .{ .cpu_arch = .mips, .os_tag = .rtems, .abi = .eabihf },

    .{ .cpu_arch = .mipsel, .os_tag = .freebsd, .abi = .eabi },
    .{ .cpu_arch = .mipsel, .os_tag = .freebsd, .abi = .eabihf },
    .{ .cpu_arch = .mipsel, .os_tag = .freestanding, .abi = .eabi },
    .{ .cpu_arch = .mipsel, .os_tag = .freestanding, .abi = .eabihf },
    .{ .cpu_arch = .mipsel, .os_tag = .linux, .abi = .eabi },
    .{ .cpu_arch = .mipsel, .os_tag = .linux, .abi = .eabihf },
    .{ .cpu_arch = .mipsel, .os_tag = .linux, .abi = .gnueabi },
    .{ .cpu_arch = .mipsel, .os_tag = .linux, .abi = .gnueabihf },
    .{ .cpu_arch = .mipsel, .os_tag = .linux, .abi = .musleabi },
    .{ .cpu_arch = .mipsel, .os_tag = .linux, .abi = .musleabihf },
    .{ .cpu_arch = .mipsel, .os_tag = .netbsd, .abi = .eabi },
    .{ .cpu_arch = .mipsel, .os_tag = .netbsd, .abi = .eabihf },
    .{ .cpu_arch = .mipsel, .os_tag = .rtems, .abi = .eabi },
    .{ .cpu_arch = .mipsel, .os_tag = .rtems, .abi = .eabihf },

    .{ .cpu_arch = .mips64, .os_tag = .freebsd, .abi = .none },
    .{ .cpu_arch = .mips64, .os_tag = .freestanding, .abi = .none },
    .{ .cpu_arch = .mips64, .os_tag = .linux, .abi = .gnuabi64 },
    .{ .cpu_arch = .mips64, .os_tag = .linux, .abi = .gnuabin32 },
    .{ .cpu_arch = .mips64, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .mips64, .os_tag = .linux, .abi = .none },
    .{ .cpu_arch = .mips64, .os_tag = .netbsd, .abi = .none },
    .{ .cpu_arch = .mips64, .os_tag = .openbsd, .abi = .none },

    .{ .cpu_arch = .mips64el, .os_tag = .freebsd, .abi = .none },
    .{ .cpu_arch = .mips64el, .os_tag = .freestanding, .abi = .none },
    .{ .cpu_arch = .mips64el, .os_tag = .linux, .abi = .gnuabi64 },
    .{ .cpu_arch = .mips64el, .os_tag = .linux, .abi = .gnuabin32 },
    .{ .cpu_arch = .mips64el, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .mips64el, .os_tag = .linux, .abi = .none },
    .{ .cpu_arch = .mips64el, .os_tag = .netbsd, .abi = .none },
    .{ .cpu_arch = .mips64el, .os_tag = .openbsd, .abi = .none },

    .{ .cpu_arch = .msp430, .os_tag = .freestanding, .abi = .none },

    .{ .cpu_arch = .nvptx, .os_tag = .cuda, .abi = .none },
    .{ .cpu_arch = .nvptx, .os_tag = .nvcl, .abi = .none },
    .{ .cpu_arch = .nvptx64, .os_tag = .cuda, .abi = .none },
    .{ .cpu_arch = .nvptx64, .os_tag = .nvcl, .abi = .none },

    .{ .cpu_arch = .powerpc, .os_tag = .aix, .abi = .eabihf },
    .{ .cpu_arch = .powerpc, .os_tag = .freebsd, .abi = .eabi },
    .{ .cpu_arch = .powerpc, .os_tag = .freebsd, .abi = .eabihf },
    .{ .cpu_arch = .powerpc, .os_tag = .freestanding, .abi = .eabi },
    .{ .cpu_arch = .powerpc, .os_tag = .freestanding, .abi = .eabihf },
    .{ .cpu_arch = .powerpc, .os_tag = .haiku, .abi = .eabi },
    .{ .cpu_arch = .powerpc, .os_tag = .haiku, .abi = .eabihf },
    .{ .cpu_arch = .powerpc, .os_tag = .linux, .abi = .eabi },
    .{ .cpu_arch = .powerpc, .os_tag = .linux, .abi = .eabihf },
    .{ .cpu_arch = .powerpc, .os_tag = .linux, .abi = .gnueabi },
    .{ .cpu_arch = .powerpc, .os_tag = .linux, .abi = .gnueabihf },
    .{ .cpu_arch = .powerpc, .os_tag = .linux, .abi = .musleabi },
    .{ .cpu_arch = .powerpc, .os_tag = .linux, .abi = .musleabihf },
    .{ .cpu_arch = .powerpc, .os_tag = .netbsd, .abi = .eabi },
    .{ .cpu_arch = .powerpc, .os_tag = .netbsd, .abi = .eabihf },
    .{ .cpu_arch = .powerpc, .os_tag = .openbsd, .abi = .eabi },
    .{ .cpu_arch = .powerpc, .os_tag = .openbsd, .abi = .eabihf },
    .{ .cpu_arch = .powerpc, .os_tag = .rtems, .abi = .eabi },
    .{ .cpu_arch = .powerpc, .os_tag = .rtems, .abi = .eabihf },

    .{ .cpu_arch = .powerpcle, .os_tag = .freestanding, .abi = .eabi },
    .{ .cpu_arch = .powerpcle, .os_tag = .freestanding, .abi = .eabihf },

    .{ .cpu_arch = .powerpc64, .os_tag = .aix, .abi = .none },
    .{ .cpu_arch = .powerpc64, .os_tag = .freebsd, .abi = .none },
    .{ .cpu_arch = .powerpc64, .os_tag = .freestanding, .abi = .none },
    .{ .cpu_arch = .powerpc64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .powerpc64, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .powerpc64, .os_tag = .linux, .abi = .none },
    .{ .cpu_arch = .powerpc64, .os_tag = .openbsd, .abi = .none },
    .{ .cpu_arch = .powerpc64, .os_tag = .rtems, .abi = .none },

    .{ .cpu_arch = .powerpc64le, .os_tag = .freebsd, .abi = .none },
    .{ .cpu_arch = .powerpc64le, .os_tag = .freestanding, .abi = .none },
    .{ .cpu_arch = .powerpc64le, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .powerpc64le, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .powerpc64le, .os_tag = .linux, .abi = .none },

    .{ .cpu_arch = .riscv32, .os_tag = .freestanding, .abi = .none },
    .{ .cpu_arch = .riscv32, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .riscv32, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .riscv32, .os_tag = .linux, .abi = .none },
    .{ .cpu_arch = .riscv32, .os_tag = .linux, .abi = .ohos },
    .{ .cpu_arch = .riscv32, .os_tag = .rtems, .abi = .none },
    .{ .cpu_arch = .riscv32, .os_tag = .uefi, .abi = .none },

    .{ .cpu_arch = .riscv64, .os_tag = .freebsd, .abi = .none },
    .{ .cpu_arch = .riscv64, .os_tag = .freestanding, .abi = .none },
    .{ .cpu_arch = .riscv64, .os_tag = .fuchsia, .abi = .none },
    .{ .cpu_arch = .riscv64, .os_tag = .haiku, .abi = .none },
    .{ .cpu_arch = .riscv64, .os_tag = .hermit, .abi = .none },
    .{ .cpu_arch = .riscv64, .os_tag = .linux, .abi = .android },
    .{ .cpu_arch = .riscv64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .riscv64, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .riscv64, .os_tag = .linux, .abi = .none },
    .{ .cpu_arch = .riscv64, .os_tag = .linux, .abi = .ohos },
    .{ .cpu_arch = .riscv64, .os_tag = .netbsd, .abi = .none },
    .{ .cpu_arch = .riscv64, .os_tag = .openbsd, .abi = .none },
    .{ .cpu_arch = .riscv64, .os_tag = .rtems, .abi = .none },
    .{ .cpu_arch = .riscv64, .os_tag = .serenity, .abi = .none },
    .{ .cpu_arch = .riscv64, .os_tag = .uefi, .abi = .none },

    .{ .cpu_arch = .s390x, .os_tag = .freestanding, .abi = .none },
    .{ .cpu_arch = .s390x, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .s390x, .os_tag = .linux, .abi = .none },
    .{ .cpu_arch = .s390x, .os_tag = .zos, .abi = .none },

    .{ .cpu_arch = .sparc, .os_tag = .freestanding, .abi = .none },
    .{ .cpu_arch = .sparc, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .sparc, .os_tag = .linux, .abi = .none },
    .{ .cpu_arch = .sparc, .os_tag = .netbsd, .abi = .none },
    .{ .cpu_arch = .sparc, .os_tag = .rtems, .abi = .none },

    .{ .cpu_arch = .sparc64, .os_tag = .freebsd, .abi = .none },
    .{ .cpu_arch = .sparc64, .os_tag = .freestanding, .abi = .none },
    .{ .cpu_arch = .sparc64, .os_tag = .haiku, .abi = .none },
    .{ .cpu_arch = .sparc64, .os_tag = .illumos, .abi = .none },
    .{ .cpu_arch = .sparc64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .sparc64, .os_tag = .linux, .abi = .none },
    .{ .cpu_arch = .sparc64, .os_tag = .netbsd, .abi = .none },
    .{ .cpu_arch = .sparc64, .os_tag = .openbsd, .abi = .none },
    .{ .cpu_arch = .sparc64, .os_tag = .rtems, .abi = .none },
    .{ .cpu_arch = .sparc64, .os_tag = .solaris, .abi = .none },

    .{ .cpu_arch = .thumb, .os_tag = .freebsd, .abi = .eabi },
    .{ .cpu_arch = .thumb, .os_tag = .freebsd, .abi = .eabihf },
    .{ .cpu_arch = .thumb, .os_tag = .freestanding, .abi = .eabi },
    .{ .cpu_arch = .thumb, .os_tag = .freestanding, .abi = .eabihf },
    .{ .cpu_arch = .thumb, .os_tag = .linux, .abi = .eabi },
    .{ .cpu_arch = .thumb, .os_tag = .linux, .abi = .eabihf },
    .{ .cpu_arch = .thumb, .os_tag = .linux, .abi = .musleabi },
    .{ .cpu_arch = .thumb, .os_tag = .linux, .abi = .musleabihf },
    .{ .cpu_arch = .thumb, .os_tag = .netbsd, .abi = .eabi },
    .{ .cpu_arch = .thumb, .os_tag = .netbsd, .abi = .eabihf },
    .{ .cpu_arch = .thumb, .os_tag = .openbsd, .abi = .eabi },
    .{ .cpu_arch = .thumb, .os_tag = .openbsd, .abi = .eabihf },
    .{ .cpu_arch = .thumb, .os_tag = .rtems, .abi = .eabi },
    .{ .cpu_arch = .thumb, .os_tag = .rtems, .abi = .eabihf },
    .{ .cpu_arch = .thumb, .os_tag = .windows, .abi = .gnu },
    .{ .cpu_arch = .thumb, .os_tag = .windows, .abi = .itanium },
    .{ .cpu_arch = .thumb, .os_tag = .windows, .abi = .msvc },

    .{ .cpu_arch = .thumbeb, .os_tag = .freebsd, .abi = .eabi },
    .{ .cpu_arch = .thumbeb, .os_tag = .freebsd, .abi = .eabihf },
    .{ .cpu_arch = .thumbeb, .os_tag = .freestanding, .abi = .eabi },
    .{ .cpu_arch = .thumbeb, .os_tag = .freestanding, .abi = .eabihf },
    .{ .cpu_arch = .thumbeb, .os_tag = .linux, .abi = .eabi },
    .{ .cpu_arch = .thumbeb, .os_tag = .linux, .abi = .eabihf },
    .{ .cpu_arch = .thumbeb, .os_tag = .linux, .abi = .musleabi },
    .{ .cpu_arch = .thumbeb, .os_tag = .linux, .abi = .musleabihf },
    .{ .cpu_arch = .thumbeb, .os_tag = .netbsd, .abi = .eabi },
    .{ .cpu_arch = .thumbeb, .os_tag = .netbsd, .abi = .eabihf },
    .{ .cpu_arch = .thumbeb, .os_tag = .rtems, .abi = .eabi },
    .{ .cpu_arch = .thumbeb, .os_tag = .rtems, .abi = .eabihf },

    .{ .cpu_arch = .ve, .os_tag = .freestanding, .abi = .none },
    .{ .cpu_arch = .ve, .os_tag = .linux, .abi = .none },

    .{ .cpu_arch = .wasm32, .os_tag = .emscripten, .abi = .none },
    .{ .cpu_arch = .wasm32, .os_tag = .freestanding, .abi = .none },
    .{ .cpu_arch = .wasm32, .os_tag = .wasi, .abi = .musl },
    .{ .cpu_arch = .wasm32, .os_tag = .wasi, .abi = .none },

    .{ .cpu_arch = .wasm64, .os_tag = .emscripten, .abi = .none },
    .{ .cpu_arch = .wasm64, .os_tag = .freestanding, .abi = .none },
    .{ .cpu_arch = .wasm64, .os_tag = .wasi, .abi = .musl },
    .{ .cpu_arch = .wasm64, .os_tag = .wasi, .abi = .none },

    .{ .cpu_arch = .x86, .os_tag = .elfiamcu, .abi = .none },
    .{ .cpu_arch = .x86, .os_tag = .freebsd, .abi = .none },
    .{ .cpu_arch = .x86, .os_tag = .freestanding, .abi = .none },
    .{ .cpu_arch = .x86, .os_tag = .haiku, .abi = .none },
    .{ .cpu_arch = .x86, .os_tag = .hurd, .abi = .gnu },
    .{ .cpu_arch = .x86, .os_tag = .linux, .abi = .android },
    .{ .cpu_arch = .x86, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .x86, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .x86, .os_tag = .linux, .abi = .none },
    .{ .cpu_arch = .x86, .os_tag = .linux, .abi = .ohos },
    .{ .cpu_arch = .x86, .os_tag = .netbsd, .abi = .none },
    .{ .cpu_arch = .x86, .os_tag = .openbsd, .abi = .none },
    .{ .cpu_arch = .x86, .os_tag = .rtems, .abi = .none },
    .{ .cpu_arch = .x86, .os_tag = .uefi, .abi = .none },
    .{ .cpu_arch = .x86, .os_tag = .windows, .abi = .gnu },
    .{ .cpu_arch = .x86, .os_tag = .windows, .abi = .itanium },
    .{ .cpu_arch = .x86, .os_tag = .windows, .abi = .msvc },

    .{ .cpu_arch = .x86_64, .os_tag = .freebsd, .abi = .none },
    .{ .cpu_arch = .x86_64, .os_tag = .freestanding, .abi = .none },
    .{
        .cpu_arch = .x86_64,
        .os_tag = .freestanding,
        .abi = .none,
        .cpu_features_add = std.Target.x86.featureSet(&.{.soft_float}),
        .cpu_features_sub = std.Target.x86.featureSet(&.{ .mmx, .sse, .sse2, .avx, .avx2 }),
    },
    .{ .cpu_arch = .x86_64, .os_tag = .fuchsia, .abi = .none },
    .{ .cpu_arch = .x86_64, .os_tag = .dragonfly, .abi = .none },
    .{ .cpu_arch = .x86_64, .os_tag = .driverkit, .abi = .none },
    .{ .cpu_arch = .x86_64, .os_tag = .haiku, .abi = .none },
    .{ .cpu_arch = .x86_64, .os_tag = .hermit, .abi = .none },
    .{ .cpu_arch = .x86_64, .os_tag = .hurd, .abi = .gnu },
    .{ .cpu_arch = .x86_64, .os_tag = .illumos, .abi = .none },
    .{ .cpu_arch = .x86_64, .os_tag = .ios, .abi = .macabi },
    .{ .cpu_arch = .x86_64, .os_tag = .ios, .abi = .simulator },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .android },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnux32 },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .muslx32 },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .none },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .ohos },
    .{ .cpu_arch = .x86_64, .os_tag = .macos, .abi = .none },
    .{ .cpu_arch = .x86_64, .os_tag = .netbsd, .abi = .none },
    .{ .cpu_arch = .x86_64, .os_tag = .openbsd, .abi = .none },
    .{ .cpu_arch = .x86_64, .os_tag = .rtems, .abi = .none },
    .{ .cpu_arch = .x86_64, .os_tag = .serenity, .abi = .none },
    .{ .cpu_arch = .x86_64, .os_tag = .solaris, .abi = .none },
    .{ .cpu_arch = .x86_64, .os_tag = .tvos, .abi = .simulator },
    .{ .cpu_arch = .x86_64, .os_tag = .uefi, .abi = .none },
    .{ .cpu_arch = .x86_64, .os_tag = .visionos, .abi = .simulator },
    .{ .cpu_arch = .x86_64, .os_tag = .watchos, .abi = .simulator },
    .{ .cpu_arch = .x86_64, .os_tag = .windows, .abi = .gnu },
    .{ .cpu_arch = .x86_64, .os_tag = .windows, .abi = .itanium },
    .{ .cpu_arch = .x86_64, .os_tag = .windows, .abi = .msvc },

    .{ .cpu_arch = .xcore, .os_tag = .freestanding, .abi = .none },

    .{ .cpu_arch = .xtensa, .os_tag = .freestanding, .abi = .none },
    .{ .cpu_arch = .xtensa, .os_tag = .linux, .abi = .none },
};

pub fn addCases(
    ctx: *Cases,
    build_options: @import("cases.zig").BuildOptions,
    b: *std.Build,
) !void {
    if (!build_options.enable_llvm) return;
    for (targets) |target_query| {
        if (target_query.cpu_arch) |arch| switch (arch) {
            .m68k => if (!build_options.llvm_has_m68k) continue,
            .csky => if (!build_options.llvm_has_csky) continue,
            .arc => if (!build_options.llvm_has_arc) continue,
            .xtensa => if (!build_options.llvm_has_xtensa) continue,
            else => {},
        };
        var case = ctx.noEmitUsingLlvmBackend("llvm_targets", b.resolveTargetQuery(target_query));
        case.addCompile("");
    }
}
