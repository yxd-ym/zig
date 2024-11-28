const std = @import("std");
const Type = @import("../../Type.zig");
const Zcu = @import("../../Zcu.zig");
const assert = std.debug.assert;

pub const Class = union(enum) {
    memory,
    byval,
};

pub fn classifyType(ty: Type, zcu: *Zcu) Class {
    const target = zcu.getTarget();
    std.debug.assert(ty.hasRuntimeBitsIgnoreComptime(zcu));

    const max_byval_size = target.ptrBitWidth() * 2;
    switch (ty.zigTypeTag(zcu)) {
        .@"struct" => {
            // FIXME
            const bit_size = ty.bitSize(zcu);
            if (bit_size > max_byval_size) return .memory;
            return .byval;
        },
        .@"union" => {
            // FIXME
            const bit_size = ty.bitSize(zcu);
            if (bit_size > max_byval_size) return .memory;
            return .byval;
        },
        .bool => return .byval,
        .float => return .byval,
        .int, .@"enum", .error_set => {
            return .byval;
        },
        .vector => {
            // FIXME
            const bit_size = ty.bitSize(zcu);
            if (bit_size > max_byval_size) return .memory;
            return .byval;
        },
        .optional => {
            std.debug.assert(ty.isPtrLikeOptional(zcu));
            return .byval;
        },
        .pointer => {
            std.debug.assert(!ty.isSlice(zcu));
            return .byval;
        },
        .error_union,
        .frame,
        .@"anyframe",
        .noreturn,
        .void,
        .type,
        .comptime_float,
        .comptime_int,
        .undefined,
        .null,
        .@"fn",
        .@"opaque",
        .enum_literal,
        .array,
        => unreachable,
    }
}
