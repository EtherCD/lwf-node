const ctx = @import("ctx.zig");
const variables = @import("variables.zig");

pub const Value = union(enum) {
    int: i64,
    int128: i128,
    string: []u8,
    boolean: bool,
    float: f32,
    double: f64,
    nullable: bool,

    pub fn encode(self: Value, context: *ctx.ContextEncode) !void {
        switch (self) {
            .int => |v| {
                if (v >= 0) {
                    try variables.TypeByte.encode(context, @as(u64, @intCast(v)), variables.range_min_uint, variables.range_max_uint);
                } else {
                    try context.buffer.append(@intFromEnum(variables.TypeByteEnum.Int));
                    try variables.Int.encode(context, v);
                }
            },
            .int128 => |val| {
                const x = @as(u128, @intCast(if (val < 0) -val else val));
                try context.buffer.append(if (val < 0) @intFromEnum(variables.TypeByteEnum.NUint128) else @intFromEnum(variables.TypeByteEnum.Uint128));
                try variables.Uint128.encode(context, x);
            },
            .string => |v| try variables.String.encode(context, v),
            .boolean => |v| {
                try context.buffer.append(if (v) @intFromEnum(variables.TypeByteEnum.True) else @intFromEnum(variables.TypeByteEnum.False));
            },
            .nullable => |_| {
                try context.buffer.append(@intFromEnum(variables.TypeByteEnum.Null));
            },
            else => unreachable,
        }
    }

    pub fn decode(context: *ctx.ContextDecode) !Value {
        const type_byte = context.peek();

        if (variables.TypeByte.in_range(type_byte, variables.range_min_uint, variables.range_min_uint)) {
            return Value{ .int = @as(i64, @intCast(variables.TypeByte.decode(context, variables.range_min_uint, variables.range_min_uint))) };
        }

        if (variables.TypeByte.in_range(type_byte, variables.range_min_str_l, variables.range_max_str_l)) {
            return Value{ .string = try variables.String.decode(context) };
        }

        _ = context.read();

        return switch (type_byte) {
            @intFromEnum(variables.TypeByteEnum.True) => Value{ .boolean = true },
            @intFromEnum(variables.TypeByteEnum.False) => Value{ .boolean = false },
            @intFromEnum(variables.TypeByteEnum.Int) => Value{ .int = try variables.Int.decode(context) },
            @intFromEnum(variables.TypeByteEnum.Uint128) => Value{ .int128 = variables.Uint128.decode(context) },
            @intFromEnum(variables.TypeByteEnum.NUint128) => Value{ .int128 = -(variables.Uint128.decode(context)) },
            @intFromEnum(variables.TypeByteEnum.Null) => Value{ .nullable = true },
            else => unreachable,
        };
    }
};
