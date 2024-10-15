const std = @import("std");
const builtin = @import("builtin");
const testing = std.testing;

// All LoongArch machines have
// 32 general-purpose registers and
// optionally 32 floating-point registers.
pub const RegisterClass = enum {
    general_purpose,
    floating_point,
};

pub const Register = enum(u8) {
    // zig fmt: off
    // GPR (General-purpose register)
    r0, r1, r2, r3, r4, r5, r6, r7,
    r8, r9, r10, r11, r12, r13, r14, r15,
    r16, r17, r18, r19, r20, r21, r22, r23,
    r24, r25, r26, r27, r28, r29, r30, r31,

    // FPR (Floating-point register)
    f0, f1, f2, f3, f4, f5, f6, f7,
    f8, f9, f10, f11, f12, f13, f14, f15,
    @"f16", f17, f18, f19, f20, f21, f22, f23,
    f24, f25, f26, f27, f28, f29, f30, f31,


    // GPR aliases
    zero,                                           // Constant zero
    ra,                                             // Return address
    tp,                                             // Thread pointer
    sp,                                             // Stack pointer
    fp,                                             // Frame pointer
    a0, a1,                                         // Argument registers / return value registers
    a2, a3, a4, a5, a6, a7,                         // Argument registers
    t0, t1, t2, t3, t4, t5, t6, t7, t8,             // Temporary registers
    s0, s1, s2, s3, s4, s5, s6, s7, s8, s9,         // Static registers

    // FPR aliases
    fa0, fa1,                                       // Argument registers / return value registers
    fa2, fa3, fa4, fa5, fa6, fa7,                   // Argument registers
    ft0, ft1, ft2, ft3, ft4, ft5, ft6, ft7,
    ft8, ft9, ft10, ft11, ft12, ft13, ft14, ft15,   // Temporary registers
    fs0, fs1, fs2, fs3, fs4, fs5, fs6, fs7,         // Static registers
    // zig fmt: on

    pub fn id(self: Register) u6 {
        return switch (@intFromEnum(self)) {
            @intFromEnum(Register.r0)...@intFromEnum(Register.r31) => @as(u6, @intCast(@intFromEnum(self))),
            @intFromEnum(Register.f0)...@intFromEnum(Register.f31) => @as(u6, @intCast(@intFromEnum(self))),

            @intFromEnum(Register.zero) => @as(u6, @intCast(@intFromEnum(Register.r0))),
            @intFromEnum(Register.ra) => @as(u6, @intCast(@intFromEnum(Register.r1))),
            @intFromEnum(Register.tp) => @as(u6, @intCast(@intFromEnum(Register.r2))),
            @intFromEnum(Register.sp) => @as(u6, @intCast(@intFromEnum(Register.r3))),
            @intFromEnum(Register.fp) => @as(u6, @intCast(@intFromEnum(Register.r22))),
            @intFromEnum(Register.a0)...@intFromEnum(Register.a7) => @as(u6, @intCast(@intFromEnum(self) - @intFromEnum(Register.a0) + @intFromEnum(Register.r4))),
            @intFromEnum(Register.t0)...@intFromEnum(Register.t8) => @as(u6, @intCast(@intFromEnum(self) - @intFromEnum(Register.t0) + @intFromEnum(Register.r12))),
            @intFromEnum(Register.s0)...@intFromEnum(Register.s8) => @as(u6, @intCast(@intFromEnum(self) - @intFromEnum(Register.s0) + @intFromEnum(Register.r23))),
            @intFromEnum(Register.s9) => @as(u6, @intCast(@intFromEnum(Register.r22))),

            @intFromEnum(Register.fa0)...@intFromEnum(Register.fa7) => @as(u6, @intCast(@intFromEnum(self) - @intFromEnum(Register.fa0) + @intFromEnum(Register.f0))),
            @intFromEnum(Register.ft0)...@intFromEnum(Register.ft15) => @as(u6, @intCast(@intFromEnum(self) - @intFromEnum(Register.ft0) + @intFromEnum(Register.f8))),
            @intFromEnum(Register.fs0)...@intFromEnum(Register.fs7) => @as(u6, @intCast(@intFromEnum(self) - @intFromEnum(Register.fs0) + @intFromEnum(Register.f24))),

            else => unreachable,
        };
    }

    pub fn class(self: Register) RegisterClass {
        return switch (self.id()) {
            Register.r0.id()...Register.r31.id() => RegisterClass.general_purpose,
            Register.f0.id()...Register.f31.id() => RegisterClass.floating_point,
        };
    }

    pub fn isAllocatable(self: Register) bool {
        return switch (self.id()) {
            Register.zero.id(), Register.tp.id(), Register.r21.id() => false,
            else => true,
        };
    }

    pub fn preservedAcrossCalls(self: Register) bool {
        return switch (self.id()) {
            Register.zero.id(), Register.tp.id(), Register.r21.id() => unreachable, // non-allocatable registers
            Register.sp.id(), Register.fp.id() => true, // sp and fp
            Register.s0.id()...Register.s8.id() => true, // static registers
            Register.fs0.id()...Register.fs7.id() => true, // floating point static registers
            else => false,
        };
    }
};

test "Register.id" {
    // regular names
    inline for (std.meta.fields(Register)) |r| {
        const reg: Register = @enumFromInt(r.value);
        const id = reg.id();

        var buf: [6]u8 = undefined;

        switch (@intFromEnum(reg)) {
            0...31 => |expected| {
                try testing.expectEqual(expected, id);

                const expected_name = try std.fmt.bufPrint(&buf, "r{}", .{expected});
                try testing.expectEqualStrings(expected_name, @tagName(reg));
            },
            32...63 => |expected| {
                try testing.expectEqual(expected, id);

                const expected_name = try std.fmt.bufPrint(&buf, "f{}", .{expected - 32});
                try testing.expectEqualStrings(expected_name, @tagName(reg));
            },
            else => {},
        }
    }

    // aliases
    const alias = struct {
        alias: Register,
        name: Register,
    };
    const table = [_]alias{
        .{ .alias = .zero, .name = .r0 },
        .{ .alias = .ra, .name = .r1 },
        .{ .alias = .tp, .name = .r2 },
        .{ .alias = .sp, .name = .r3 },
        .{ .alias = .fp, .name = .r22 },

        .{ .alias = .a0, .name = .r4 },
        .{ .alias = .a1, .name = .r5 },
        .{ .alias = .a2, .name = .r6 },
        .{ .alias = .a3, .name = .r7 },
        .{ .alias = .a4, .name = .r8 },
        .{ .alias = .a5, .name = .r9 },
        .{ .alias = .a6, .name = .r10 },
        .{ .alias = .a7, .name = .r11 },

        .{ .alias = .t0, .name = .r12 },
        .{ .alias = .t1, .name = .r13 },
        .{ .alias = .t2, .name = .r14 },
        .{ .alias = .t3, .name = .r15 },
        .{ .alias = .t4, .name = .r16 },
        .{ .alias = .t5, .name = .r17 },
        .{ .alias = .t6, .name = .r18 },
        .{ .alias = .t7, .name = .r19 },
        .{ .alias = .t8, .name = .r20 },

        .{ .alias = .s0, .name = .r23 },
        .{ .alias = .s1, .name = .r24 },
        .{ .alias = .s2, .name = .r25 },
        .{ .alias = .s3, .name = .r26 },
        .{ .alias = .s4, .name = .r27 },
        .{ .alias = .s5, .name = .r28 },
        .{ .alias = .s6, .name = .r29 },
        .{ .alias = .s7, .name = .r30 },
        .{ .alias = .s8, .name = .r31 },
        .{ .alias = .s9, .name = .r22 },

        .{ .alias = .fa0, .name = .f0 },
        .{ .alias = .fa1, .name = .f1 },
        .{ .alias = .fa2, .name = .f2 },
        .{ .alias = .fa3, .name = .f3 },
        .{ .alias = .fa4, .name = .f4 },
        .{ .alias = .fa5, .name = .f5 },
        .{ .alias = .fa6, .name = .f6 },
        .{ .alias = .fa7, .name = .f7 },

        .{ .alias = .ft0, .name = .f8 },
        .{ .alias = .ft1, .name = .f9 },
        .{ .alias = .ft2, .name = .f10 },
        .{ .alias = .ft3, .name = .f11 },
        .{ .alias = .ft4, .name = .f12 },
        .{ .alias = .ft5, .name = .f13 },
        .{ .alias = .ft6, .name = .f14 },
        .{ .alias = .ft7, .name = .f15 },
        .{ .alias = .ft8, .name = .f16 },
        .{ .alias = .ft9, .name = .f17 },
        .{ .alias = .ft10, .name = .f18 },
        .{ .alias = .ft11, .name = .f19 },
        .{ .alias = .ft12, .name = .f20 },
        .{ .alias = .ft13, .name = .f21 },
        .{ .alias = .ft14, .name = .f22 },
        .{ .alias = .ft15, .name = .f23 },

        .{ .alias = .fs0, .name = .f24 },
        .{ .alias = .fs1, .name = .f25 },
        .{ .alias = .fs2, .name = .f26 },
        .{ .alias = .fs3, .name = .f27 },
        .{ .alias = .fs4, .name = .f28 },
        .{ .alias = .fs5, .name = .f29 },
        .{ .alias = .fs6, .name = .f30 },
        .{ .alias = .fs7, .name = .f31 },
    };

    inline for (table) |item| {
        const expected = item.name.id();
        const alias_id = item.alias.id();

        try testing.expect(item.name != item.alias);
        try testing.expectEqual(expected, alias_id);
    }
}

test "Register.class" {
    inline for (std.meta.fields(Register)) |r| {
        const reg: Register = @enumFromInt(r.value);
        const id = reg.id();
        const class = reg.class();

        switch (id) {
            0...31 => {
                try testing.expectEqual(RegisterClass.general_purpose, class);
            },
            32...63 => {
                try testing.expectEqual(RegisterClass.floating_point, class);
            },
        }
    }
}
