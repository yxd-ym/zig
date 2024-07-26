//! To get started, run this tool with no args and read the help message.
//!
//! This tool extracts the Linux syscall numbers from the Linux source tree
//! directly, and emits an enumerated list per supported Zig arch.

const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const zig = std.zig;
const fs = std.fs;

const stdlib_renames = std.StaticStringMap([]const u8).initComptime(.{
    // Remove underscore prefix.
    .{ "_llseek", "llseek" },
    .{ "_newselect", "newselect" },
    .{ "_sysctl", "sysctl" },
    // Most 64-bit archs.
    .{ "newfstat", "fstat64" },
    .{ "newfstatat", "fstatat64" },
    // POWER.
    .{ "sync_file_range2", "sync_file_range" },
    // ARM EABI/Thumb.
    .{ "arm_sync_file_range", "sync_file_range" },
    .{ "arm_fadvise64_64", "fadvise64_64" },
});

// Only for newer architectures where we use the C preprocessor.
const stdlib_renames_new = std.StaticStringMap([]const u8).initComptime(.{
    .{ "newuname", "uname" },
    .{ "umount", "umount2" },
});

// We use this to deal with the fact that multiple syscalls can be mapped to sys_ni_syscall.
// Thankfully it's only 2 well-known syscalls in newer kernel ports at the moment.
fn getOverridenNameNew(value: []const u8) ?[]const u8 {
    if (mem.eql(u8, value, "18")) {
        return "sys_lookup_dcookie";
    } else if (mem.eql(u8, value, "42")) {
        return "sys_nfsservctl";
    } else {
        return null;
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    if (args.len < 3 or mem.eql(u8, args[1], "--help"))
        usageAndExit(std.io.getStdErr(), args[0], 1);
    const zig_exe = args[1];
    const linux_path = args[2];

    var buf_out = std.io.bufferedWriter(std.io.getStdOut().writer());
    const writer = buf_out.writer();

    // As of 5.17.1, the largest table is 23467 bytes.
    // 32k should be enough for now.
    const buf = try allocator.alloc(u8, 1 << 15);
    const linux_dir = try std.fs.openDirAbsolute(linux_path, .{});

    try writer.writeAll(
        \\// This file is automatically generated.
        \\// See tools/generate_linux_syscalls.zig for more info.
        \\
        \\
    );

    // These architectures have their syscall definitions generated from a TSV
    // file, processed via scripts/syscallhdr.sh.
    {
        try writer.writeAll("pub const X86 = enum(usize) {\n");

        const table = try linux_dir.readFile("arch/x86/entry/syscalls/syscall_32.tbl", buf);
        var lines = mem.tokenizeScalar(u8, table, '\n');
        while (lines.next()) |line| {
            if (line[0] == '#') continue;

            var fields = mem.tokenizeAny(u8, line, " \t");
            const number = fields.next() orelse return error.Incomplete;
            // abi is always i386
            _ = fields.next() orelse return error.Incomplete;
            const name = fields.next() orelse return error.Incomplete;
            const fixed_name = if (stdlib_renames.get(name)) |fixed| fixed else name;

            try writer.print("    {p} = {s},\n", .{ zig.fmtId(fixed_name), number });
        }

        try writer.writeAll("};\n\n");
    }
    {
        try writer.writeAll("pub const X64 = enum(usize) {\n");

        const table = try linux_dir.readFile("arch/x86/entry/syscalls/syscall_64.tbl", buf);
        var lines = mem.tokenizeScalar(u8, table, '\n');
        while (lines.next()) |line| {
            if (line[0] == '#') continue;

            var fields = mem.tokenizeAny(u8, line, " \t");
            const number = fields.next() orelse return error.Incomplete;
            const abi = fields.next() orelse return error.Incomplete;
            // The x32 abi syscalls are always at the end.
            if (mem.eql(u8, abi, "x32")) break;
            const name = fields.next() orelse return error.Incomplete;
            const fixed_name = if (stdlib_renames.get(name)) |fixed| fixed else name;

            try writer.print("    {p} = {s},\n", .{ zig.fmtId(fixed_name), number });
        }

        try writer.writeAll("};\n\n");
    }
    {
        try writer.writeAll(
            \\pub const Arm = enum(usize) {
            \\    const arm_base = 0x0f0000;
            \\
            \\
        );

        const table = try linux_dir.readFile("arch/arm/tools/syscall.tbl", buf);
        var lines = mem.tokenizeScalar(u8, table, '\n');
        while (lines.next()) |line| {
            if (line[0] == '#') continue;

            var fields = mem.tokenizeAny(u8, line, " \t");
            const number = fields.next() orelse return error.Incomplete;
            const abi = fields.next() orelse return error.Incomplete;
            if (mem.eql(u8, abi, "oabi")) continue;
            const name = fields.next() orelse return error.Incomplete;
            const fixed_name = if (stdlib_renames.get(name)) |fixed| fixed else name;

            try writer.print("    {p} = {s},\n", .{ zig.fmtId(fixed_name), number });
        }

        // TODO: maybe extract these from arch/arm/include/uapi/asm/unistd.h
        try writer.writeAll(
            \\
            \\    breakpoint = arm_base + 1,
            \\    cacheflush = arm_base + 2,
            \\    usr26 = arm_base + 3,
            \\    usr32 = arm_base + 4,
            \\    set_tls = arm_base + 5,
            \\    get_tls = arm_base + 6,
            \\};
            \\
            \\
        );
    }
    {
        try writer.writeAll("pub const Sparc = enum(usize) {\n");
        const table = try linux_dir.readFile("arch/sparc/kernel/syscalls/syscall.tbl", buf);
        var lines = mem.tokenizeScalar(u8, table, '\n');
        while (lines.next()) |line| {
            if (line[0] == '#') continue;

            var fields = mem.tokenizeAny(u8, line, " \t");
            const number = fields.next() orelse return error.Incomplete;
            const abi = fields.next() orelse return error.Incomplete;
            if (mem.eql(u8, abi, "64")) continue;
            const name = fields.next() orelse return error.Incomplete;
            const fixed_name = if (stdlib_renames.get(name)) |fixed| fixed else name;

            try writer.print("    {p} = {s},\n", .{ zig.fmtId(fixed_name), number });
        }

        try writer.writeAll("};\n\n");
    }
    {
        try writer.writeAll("pub const Sparc64 = enum(usize) {\n");
        const table = try linux_dir.readFile("arch/sparc/kernel/syscalls/syscall.tbl", buf);
        var lines = mem.tokenizeScalar(u8, table, '\n');
        while (lines.next()) |line| {
            if (line[0] == '#') continue;

            var fields = mem.tokenizeAny(u8, line, " \t");
            const number = fields.next() orelse return error.Incomplete;
            const abi = fields.next() orelse return error.Incomplete;
            if (mem.eql(u8, abi, "32")) continue;
            const name = fields.next() orelse return error.Incomplete;
            const fixed_name = if (stdlib_renames.get(name)) |fixed| fixed else name;

            try writer.print("    {p} = {s},\n", .{ zig.fmtId(fixed_name), number });
        }

        try writer.writeAll("};\n\n");
    }
    {
        try writer.writeAll("pub const M68k = enum(usize) {\n");

        const table = try linux_dir.readFile("arch/m68k/kernel/syscalls/syscall.tbl", buf);
        var lines = mem.tokenizeScalar(u8, table, '\n');
        while (lines.next()) |line| {
            if (line[0] == '#') continue;

            var fields = mem.tokenizeAny(u8, line, " \t");
            const number = fields.next() orelse return error.Incomplete;
            // abi is always common
            _ = fields.next() orelse return error.Incomplete;
            const name = fields.next() orelse return error.Incomplete;
            const fixed_name = if (stdlib_renames.get(name)) |fixed| fixed else name;

            try writer.print("    {p} = {s},\n", .{ zig.fmtId(fixed_name), number });
        }

        try writer.writeAll("};\n\n");
    }
    {
        try writer.writeAll(
            \\pub const MipsO32 = enum(usize) {
            \\    const linux_base = 4000;
            \\
            \\
        );

        const table = try linux_dir.readFile("arch/mips/kernel/syscalls/syscall_o32.tbl", buf);
        var lines = mem.tokenizeScalar(u8, table, '\n');
        while (lines.next()) |line| {
            if (line[0] == '#') continue;

            var fields = mem.tokenizeAny(u8, line, " \t");
            const number = fields.next() orelse return error.Incomplete;
            // abi is always o32
            _ = fields.next() orelse return error.Incomplete;
            const name = fields.next() orelse return error.Incomplete;
            if (mem.startsWith(u8, name, "unused")) continue;
            const fixed_name = if (stdlib_renames.get(name)) |fixed| fixed else name;

            try writer.print("    {p} = linux_base + {s},\n", .{ zig.fmtId(fixed_name), number });
        }

        try writer.writeAll("};\n\n");
    }
    {
        try writer.writeAll(
            \\pub const MipsN64 = enum(usize) {
            \\    const linux_base = 5000;
            \\
            \\
        );

        const table = try linux_dir.readFile("arch/mips/kernel/syscalls/syscall_n64.tbl", buf);
        var lines = mem.tokenizeScalar(u8, table, '\n');
        while (lines.next()) |line| {
            if (line[0] == '#') continue;

            var fields = mem.tokenizeAny(u8, line, " \t");
            const number = fields.next() orelse return error.Incomplete;
            // abi is always n64
            _ = fields.next() orelse return error.Incomplete;
            const name = fields.next() orelse return error.Incomplete;
            const fixed_name = if (stdlib_renames.get(name)) |fixed| fixed else name;

            try writer.print("    {p} = linux_base + {s},\n", .{ zig.fmtId(fixed_name), number });
        }

        try writer.writeAll("};\n\n");
    }
    {
        try writer.writeAll(
            \\pub const MipsN32 = enum(usize) {
            \\    const linux_base = 6000;
            \\
            \\
        );

        const table = try linux_dir.readFile("arch/mips/kernel/syscalls/syscall_n32.tbl", buf);
        var lines = mem.tokenizeScalar(u8, table, '\n');
        while (lines.next()) |line| {
            if (line[0] == '#') continue;

            var fields = mem.tokenizeAny(u8, line, " \t");
            const number = fields.next() orelse return error.Incomplete;
            // abi is always n32
            _ = fields.next() orelse return error.Incomplete;
            const name = fields.next() orelse return error.Incomplete;
            const fixed_name = if (stdlib_renames.get(name)) |fixed| fixed else name;

            try writer.print("    {p} = linux_base + {s},\n", .{ zig.fmtId(fixed_name), number });
        }

        try writer.writeAll("};\n\n");
    }
    {
        try writer.writeAll("pub const PowerPC = enum(usize) {\n");

        const table = try linux_dir.readFile("arch/powerpc/kernel/syscalls/syscall.tbl", buf);
        var list_64 = std.ArrayList(u8).init(allocator);
        var lines = mem.tokenizeScalar(u8, table, '\n');
        while (lines.next()) |line| {
            if (line[0] == '#') continue;

            var fields = mem.tokenizeAny(u8, line, " \t");
            const number = fields.next() orelse return error.Incomplete;
            const abi = fields.next() orelse return error.Incomplete;
            const name = fields.next() orelse return error.Incomplete;
            const fixed_name = if (stdlib_renames.get(name)) |fixed| fixed else name;

            if (mem.eql(u8, abi, "spu")) {
                continue;
            } else if (mem.eql(u8, abi, "32")) {
                try writer.print("    {p} = {s},\n", .{ zig.fmtId(fixed_name), number });
            } else if (mem.eql(u8, abi, "64")) {
                try list_64.writer().print("    {p} = {s},\n", .{ zig.fmtId(fixed_name), number });
            } else { // common/nospu
                try writer.print("    {p} = {s},\n", .{ zig.fmtId(fixed_name), number });
                try list_64.writer().print("    {p} = {s},\n", .{ zig.fmtId(fixed_name), number });
            }
        }

        try writer.writeAll(
            \\};
            \\
            \\pub const PowerPC64 = enum(usize) {
            \\
        );
        try writer.writeAll(list_64.items);
        try writer.writeAll("};\n\n");
    }
    {
        try writer.writeAll("pub const S390x = enum(usize) {\n");

        const table = try linux_dir.readFile("arch/s390/kernel/syscalls/syscall.tbl", buf);
        var lines = mem.tokenizeScalar(u8, table, '\n');
        while (lines.next()) |line| {
            if (line[0] == '#') continue;

            var fields = mem.tokenizeAny(u8, line, " \t");
            const number = fields.next() orelse return error.Incomplete;
            const abi = fields.next() orelse return error.Incomplete;
            if (mem.eql(u8, abi, "32")) continue; // 32-bit s390 support in linux is deprecated
            const name = fields.next() orelse return error.Incomplete;
            const fixed_name = if (stdlib_renames.get(name)) |fixed| fixed else name;

            try writer.print("    {p} = {s},\n", .{ zig.fmtId(fixed_name), number });
        }

        try writer.writeAll("};\n\n");
    }

    // Newer architectures (starting with aarch64 c. 2012) now use the same C
    // header file for their syscall numbers. Arch-specific headers are used to
    // define pre-proc. vars that add additional (usually obsolete) syscalls.
    {
        try writer.writeAll("pub const Arm64 = enum(usize) {\n");

        const child_args = [_][]const u8{
            zig_exe,
            "cc",
            "-target",
            "aarch64-linux-gnu",
            "-E",
            // -dM is cleaner, but -dD preserves iteration order.
            "-dD",
            // No need for line-markers.
            "-P",
            "-nostdinc",
            // Using -I=[dir] includes the zig linux headers, which we don't want.
            "-Itools/include",
            "-Itools/include/uapi",
            // Output the syscall in a format we can easily recognize.
            "-D __SYSCALL(nr, nm)=zigsyscall nm nr",
            "arch/arm64/include/uapi/asm/unistd.h",
        };

        const child_result = try std.process.Child.run(.{
            .allocator = allocator,
            .argv = &child_args,
            .cwd = linux_path,
            .cwd_dir = linux_dir,
        });
        if (child_result.stderr.len > 0) std.debug.print("{s}\n", .{child_result.stderr});

        const defines = switch (child_result.term) {
            .Exited => |code| if (code == 0) child_result.stdout else {
                std.debug.print("zig cc exited with code {d}\n", .{code});
                std.process.exit(1);
            },
            else => {
                std.debug.print("zig cc crashed\n", .{});
                std.process.exit(1);
            },
        };

        var lines = mem.tokenizeScalar(u8, defines, '\n');
        while (lines.next()) |line| {
            var fields = mem.tokenizeAny(u8, line, " ");
            const prefix = fields.next() orelse return error.Incomplete;

            if (!mem.eql(u8, prefix, "zigsyscall")) continue;

            const sys_name = fields.next() orelse return error.Incomplete;
            const value = fields.rest();
            const name = (getOverridenNameNew(value) orelse sys_name)["sys_".len..];
            const fixed_name = if (stdlib_renames_new.get(name)) |f| f else if (stdlib_renames.get(name)) |f| f else name;

            try writer.print("    {p} = {s},\n", .{ zig.fmtId(fixed_name), value });
        }

        try writer.writeAll("};\n\n");
    }
    {
        try writer.writeAll("pub const RiscV32 = enum(usize) {\n");

        const child_args = [_][]const u8{
            zig_exe,
            "cc",
            "-target",
            "riscv32-linux-gnuilp32",
            "-E",
            "-dD",
            "-P",
            "-nostdinc",
            "-Itools/include",
            "-Itools/include/uapi",
            "-D __SYSCALL(nr, nm)=zigsyscall nm nr",
            "arch/riscv/include/uapi/asm/unistd.h",
        };

        const child_result = try std.process.Child.run(.{
            .allocator = allocator,
            .argv = &child_args,
            .cwd = linux_path,
            .cwd_dir = linux_dir,
        });
        if (child_result.stderr.len > 0) std.debug.print("{s}\n", .{child_result.stderr});

        const defines = switch (child_result.term) {
            .Exited => |code| if (code == 0) child_result.stdout else {
                std.debug.print("zig cc exited with code {d}\n", .{code});
                std.process.exit(1);
            },
            else => {
                std.debug.print("zig cc crashed\n", .{});
                std.process.exit(1);
            },
        };

        var lines = mem.tokenizeScalar(u8, defines, '\n');
        while (lines.next()) |line| {
            var fields = mem.tokenizeAny(u8, line, " ");
            const prefix = fields.next() orelse return error.Incomplete;

            if (!mem.eql(u8, prefix, "zigsyscall")) continue;

            const sys_name = fields.next() orelse return error.Incomplete;
            const value = fields.rest();
            const name = (getOverridenNameNew(value) orelse sys_name)["sys_".len..];
            const fixed_name = if (stdlib_renames_new.get(name)) |f| f else if (stdlib_renames.get(name)) |f| f else name;

            try writer.print("    {p} = {s},\n", .{ zig.fmtId(fixed_name), value });
        }

        try writer.writeAll("};\n\n");
    }
    {
        try writer.writeAll("pub const RiscV64 = enum(usize) {\n");

        const child_args = [_][]const u8{
            zig_exe,
            "cc",
            "-target",
            "riscv64-linux-gnu",
            "-E",
            "-dD",
            "-P",
            "-nostdinc",
            "-Itools/include",
            "-Itools/include/uapi",
            "-D __SYSCALL(nr, nm)=zigsyscall nm nr",
            "arch/riscv/include/uapi/asm/unistd.h",
        };

        const child_result = try std.process.Child.run(.{
            .allocator = allocator,
            .argv = &child_args,
            .cwd = linux_path,
            .cwd_dir = linux_dir,
        });
        if (child_result.stderr.len > 0) std.debug.print("{s}\n", .{child_result.stderr});

        const defines = switch (child_result.term) {
            .Exited => |code| if (code == 0) child_result.stdout else {
                std.debug.print("zig cc exited with code {d}\n", .{code});
                std.process.exit(1);
            },
            else => {
                std.debug.print("zig cc crashed\n", .{});
                std.process.exit(1);
            },
        };

        var lines = mem.tokenizeScalar(u8, defines, '\n');
        while (lines.next()) |line| {
            var fields = mem.tokenizeAny(u8, line, " ");
            const prefix = fields.next() orelse return error.Incomplete;

            if (!mem.eql(u8, prefix, "zigsyscall")) continue;

            const sys_name = fields.next() orelse return error.Incomplete;
            const value = fields.rest();
            const name = (getOverridenNameNew(value) orelse sys_name)["sys_".len..];
            const fixed_name = if (stdlib_renames_new.get(name)) |f| f else if (stdlib_renames.get(name)) |f| f else name;

            try writer.print("    {p} = {s},\n", .{ zig.fmtId(fixed_name), value });
        }

        try writer.writeAll("};\n\n");
    }
    {
        try writer.writeAll("pub const LoongArch64 = enum(usize) {\n");

        const child_args = [_][]const u8{
            zig_exe,
            "cc",
            "-target",
            "loongarch64-linux-gnu",
            "-E",
            "-dD",
            "-P",
            "-nostdinc",
            "-Itools/include",
            "-Itools/include/uapi",
            "-D __SYSCALL(nr, nm)=zigsyscall nm nr",
            "arch/loongarch/include/uapi/asm/unistd.h",
        };

        const child_result = try std.process.Child.run(.{
            .allocator = allocator,
            .argv = &child_args,
            .cwd = linux_path,
            .cwd_dir = linux_dir,
        });
        if (child_result.stderr.len > 0) std.debug.print("{s}\n", .{child_result.stderr});

        const defines = switch (child_result.term) {
            .Exited => |code| if (code == 0) child_result.stdout else {
                std.debug.print("zig cc exited with code {d}\n", .{code});
                std.process.exit(1);
            },
            else => {
                std.debug.print("zig cc crashed\n", .{});
                std.process.exit(1);
            },
        };

        var lines = mem.tokenizeScalar(u8, defines, '\n');
        while (lines.next()) |line| {
            var fields = mem.tokenizeAny(u8, line, " ");
            const prefix = fields.next() orelse return error.Incomplete;

            if (!mem.eql(u8, prefix, "zigsyscall")) continue;

            const sys_name = fields.next() orelse return error.Incomplete;
            const value = fields.rest();
            const name = (getOverridenNameNew(value) orelse sys_name)["sys_".len..];
            const fixed_name = if (stdlib_renames_new.get(name)) |f| f else if (stdlib_renames.get(name)) |f| f else name;

            try writer.print("    {p} = {s},\n", .{ zig.fmtId(fixed_name), value });
        }

        try writer.writeAll("};\n\n");
    }
    {
        try writer.writeAll("pub const Arc = enum(usize) {\n");

        const child_args = [_][]const u8{
            zig_exe,
            "cc",
            "-target",
            "arc-freestanding-none",
            "-E",
            "-dD",
            "-P",
            "-nostdinc",
            "-Itools/include",
            "-Itools/include/uapi",
            "-D __SYSCALL(nr, nm)=zigsyscall nm nr",
            "arch/arc/include/uapi/asm/unistd.h",
        };

        const child_result = try std.process.Child.run(.{
            .allocator = allocator,
            .argv = &child_args,
            .cwd = linux_path,
            .cwd_dir = linux_dir,
        });
        if (child_result.stderr.len > 0) std.debug.print("{s}\n", .{child_result.stderr});

        const defines = switch (child_result.term) {
            .Exited => |code| if (code == 0) child_result.stdout else {
                std.debug.print("zig cc exited with code {d}\n", .{code});
                std.process.exit(1);
            },
            else => {
                std.debug.print("zig cc crashed\n", .{});
                std.process.exit(1);
            },
        };

        var lines = mem.tokenizeScalar(u8, defines, '\n');
        while (lines.next()) |line| {
            var fields = mem.tokenizeAny(u8, line, " ");
            const prefix = fields.next() orelse return error.Incomplete;

            if (!mem.eql(u8, prefix, "zigsyscall")) continue;

            const sys_name = fields.next() orelse return error.Incomplete;
            const value = fields.rest();
            const name = (getOverridenNameNew(value) orelse sys_name)["sys_".len..];
            const fixed_name = if (stdlib_renames_new.get(name)) |f| f else if (stdlib_renames.get(name)) |f| f else name;

            try writer.print("    {p} = {s},\n", .{ zig.fmtId(fixed_name), value });
        }

        try writer.writeAll("};\n\n");
    }
    {
        try writer.writeAll("pub const CSky = enum(usize) {\n");

        const child_args = [_][]const u8{
            zig_exe,
            "cc",
            "-target",
            "csky-freestanding-none",
            "-E",
            "-dD",
            "-P",
            "-nostdinc",
            "-Itools/include",
            "-Itools/include/uapi",
            "-D __SYSCALL(nr, nm)=zigsyscall nm nr",
            "arch/csky/include/uapi/asm/unistd.h",
        };

        const child_result = try std.process.Child.run(.{
            .allocator = allocator,
            .argv = &child_args,
            .cwd = linux_path,
            .cwd_dir = linux_dir,
        });
        if (child_result.stderr.len > 0) std.debug.print("{s}\n", .{child_result.stderr});

        const defines = switch (child_result.term) {
            .Exited => |code| if (code == 0) child_result.stdout else {
                std.debug.print("zig cc exited with code {d}\n", .{code});
                std.process.exit(1);
            },
            else => {
                std.debug.print("zig cc crashed\n", .{});
                std.process.exit(1);
            },
        };

        var lines = mem.tokenizeScalar(u8, defines, '\n');
        while (lines.next()) |line| {
            var fields = mem.tokenizeAny(u8, line, " ");
            const prefix = fields.next() orelse return error.Incomplete;

            if (!mem.eql(u8, prefix, "zigsyscall")) continue;

            const sys_name = fields.next() orelse return error.Incomplete;
            const value = fields.rest();
            const name = (getOverridenNameNew(value) orelse sys_name)["sys_".len..];
            const fixed_name = if (stdlib_renames_new.get(name)) |f| f else if (stdlib_renames.get(name)) |f| f else name;

            try writer.print("    {p} = {s},\n", .{ zig.fmtId(fixed_name), value });
        }

        try writer.writeAll("};\n\n");
    }
    {
        try writer.writeAll("pub const Hexagon = enum(usize) {\n");

        const child_args = [_][]const u8{
            zig_exe,
            "cc",
            "-target",
            "hexagon-freestanding-none",
            "-E",
            "-dD",
            "-P",
            "-nostdinc",
            "-Itools/include",
            "-Itools/include/uapi",
            "-D __SYSCALL(nr, nm)=zigsyscall nm nr",
            "arch/hexagon/include/uapi/asm/unistd.h",
        };

        const child_result = try std.process.Child.run(.{
            .allocator = allocator,
            .argv = &child_args,
            .cwd = linux_path,
            .cwd_dir = linux_dir,
        });
        if (child_result.stderr.len > 0) std.debug.print("{s}\n", .{child_result.stderr});

        const defines = switch (child_result.term) {
            .Exited => |code| if (code == 0) child_result.stdout else {
                std.debug.print("zig cc exited with code {d}\n", .{code});
                std.process.exit(1);
            },
            else => {
                std.debug.print("zig cc crashed\n", .{});
                std.process.exit(1);
            },
        };

        var lines = mem.tokenizeScalar(u8, defines, '\n');
        while (lines.next()) |line| {
            var fields = mem.tokenizeAny(u8, line, " ");
            const prefix = fields.next() orelse return error.Incomplete;

            if (!mem.eql(u8, prefix, "zigsyscall")) continue;

            const sys_name = fields.next() orelse return error.Incomplete;
            const value = fields.rest();
            const name = (getOverridenNameNew(value) orelse sys_name)["sys_".len..];
            const fixed_name = if (stdlib_renames_new.get(name)) |f| f else if (stdlib_renames.get(name)) |f| f else name;

            try writer.print("    {p} = {s},\n", .{ zig.fmtId(fixed_name), value });
        }

        try writer.writeAll("};\n\n");
    }

    try buf_out.flush();
}

fn usageAndExit(file: fs.File, arg0: []const u8, code: u8) noreturn {
    file.writer().print(
        \\Usage: {s} /path/to/zig /path/to/linux
        \\Alternative Usage: zig run /path/to/git/zig/tools/generate_linux_syscalls.zig -- /path/to/zig /path/to/linux
        \\
        \\Generates the list of Linux syscalls for each supported cpu arch, using the Linux development tree.
        \\Prints to stdout Zig code which you can use to replace the file lib/std/os/linux/syscalls.zig.
        \\
    , .{arg0}) catch std.process.exit(1);
    std.process.exit(code);
}
