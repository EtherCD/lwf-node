const ctx = @import("ctx.zig");
const allocator = @import("std").heap.c_allocator;

pub const TypeByteEnum = enum(u8) { Int = 0, Uint128, NUint128, Float, Double, FloatFe, NFloatFe, False, True, Null, Empty = 0x0e, EmptyCount };

const bool_true = 0x08;
const bool_false = 0x07;

pub const range_min_uint = 0x10;
pub const range_max_uint = 0x87;

pub const range_min_str_l = 0x88;
pub const range_max_str_l = 0xff;

fn zigzagEncoding(input: i64) u64 {
    return @as(u64, @intCast((input << 1) ^ (input >> 63)));
}

fn zigzagDecode(n: u64) i64 {
    return @as(i64, @intCast(n >> 1)) ^ -@as(i64, @intCast(n & 1));
}

pub const Uint = struct {
    pub fn encode(comptime T: type, context: *ctx.ContextEncode, value: T) !void {
        var x = value;

        while (x > 0x7F) {
            const current = (x & 0x7F) | 0x80;
            try context.buffer.append(@as(u8, @intCast(current)));
            x >>= 7;
            x -= 1;
        }

        try context.buffer.append(@as(u8, @intCast(x & 0x7F)));
    }

    pub fn decode(comptime T: type, context: *ctx.ContextDecode) T {
        var x: u64 = 0;
        var shift: u6 = 0;

        while (true) {
            const b = context.read();
            x += @as(u64, b & 0xFF) << shift;
            if ((b & 0x80) == 0) {
                break;
            }
            shift += 7;
        }

        return x;
    }
};

pub const Int = struct {
    pub fn encode(context: *ctx.ContextEncode, value: i64) !void {
        try Uint.encode(u64, context, zigzagEncoding(value));
    }
    pub fn decode(context: *ctx.ContextDecode) !i64 {
        return zigzagDecode(Uint.decode(u64, context));
    }
};

pub const Uint128 = struct {
    pub fn encode(context: *ctx.ContextEncode, value: u128) !void {
        try Uint.encode(u128, context, value);
    }
    pub fn decode(context: *ctx.ContextDecode) !i128 {
        Uint.decode(u128, context);
    }
};

pub const TypeByte = struct {
    pub fn encode(context: *ctx.ContextEncode, value: u64, min: u8, max: u8) !void {
        const range = max - min;
        if (value < range) {
            try context.buffer.append(@as(u8, @intCast(value)) + min);
        } else {
            try context.buffer.append(@as(u8, @intCast(value)) + min);
            try Uint.encode(u64, context, value - range);
        }
    }
    pub fn decode(context: *ctx.ContextDecode, min: u8, max: u8) u64 {
        const byte = context.buffer[context.offset.*];
        context.offset.* += 1;
        const range = max - min;
        if (byte >= min and byte < max) {
            return byte - min;
        } else {
            return Uint.decode(u64, context) + range;
        }
    }
    pub fn in_range(value: u8, min: u8, max: u8) bool {
        return value >= min and value <= max;
    }
};

pub const String = struct {
    pub fn encode(context: *ctx.ContextEncode, value: []u8) !void {
        try TypeByte.encode(context, @as(u64, @bitCast(value.len)), range_min_str_l, range_max_str_l);

        for (value) |val| {
            try context.buffer.append(val);
        }
    }
    pub fn decode(context: *ctx.ContextDecode) ![]u8 {
        const length = @as(usize, @intCast(TypeByte.decode(context, range_min_str_l, range_max_str_l)));

        var str: []u8 = try allocator.alloc(u8, length);

        var i: usize = 0;
        while (context.offset.* < length) {
            str[i] = context.buffer[context.offset.*];
            context.offset.* += 1;
            i += 1;
        }

        return str;
    }
};
