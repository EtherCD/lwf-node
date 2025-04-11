const std = @import("std");

pub const TypeByte = enum(u8) { Int = 0, Uint128, NUint128, Float, Double, FloatFe, NFloatFe, False, True, Null, Empty = 0x0e, EmptyCount };

const bool_true = 0x08;
const bool_false = 0x07;

const range_min_uint = 0x10;
const range_max_uint = 0x87;

const range_min_str_l = 0x88;
const range_max_str_l = 0xff;

fn zigzagEncoding(input: i64) u64 {
    return @as(u64, @intCast((input << 1) ^ (input >> 63)));
}

fn zigzagDecode(n: u64) i64 {
    return @as(i64, @intCast(n >> 1)) ^ -@as(i64, @intCast(n & 1));
}

pub fn encodeInt(array: *std.ArrayList(u8), input: i64) !void {
    try encodeUint(array, zigzagEncoding(input));
}

pub fn decodeInt(array: std.ArrayList(u8), offset: usize) !i64 {
    return zigzagDecode(try _local_decodeUint(array, offset));
}

fn _local_encodeUint(array: *std.ArrayList(u8), val: u64) !void {
    var x = val;

    while (x > 0x7F) {
        const current = (x & 0x7F) | 0x80;
        try array.append(@as(u8, @intCast(current)));
        x >>= 7;
        x -= 1;
    }

    try array.append(@as(u8, @intCast(x & 0x7F)));
}

fn _local_decodeUint(array: std.ArrayList(u8), offset: usize) !u64 {
    var x: u64 = 0;
    var shift: u6 = 0;

    var i = offset;

    while (true) {
        const b = array.items.ptr[i];
        i += 1;
        x += @as(u64, b & 0xFF) << shift;
        if ((b & 0x80) == 0) {
            break;
        }
        shift += 7;
    }

    return x;
}

pub fn encodeUint(array: *std.ArrayList(u8), value: u64) !void {
    try encodeNumberType(array, value, range_min_uint, range_max_uint);
}

pub fn encodeBigInt(array: *std.ArrayList(u8), val: i128) !void {
    var x = @as(u128, @intCast(if (val < 0) -val else val));
    try array.append(if (val < 0) @intFromEnum(TypeByte.NUint128) else @intFromEnum(TypeByte.Uint128));

    while (x > 0x7F) {
        const current = (x & 0x7F) | 0x80;
        try array.append(@as(u8, @intCast(current)));
        x >>= 7;
        x -= 1;
    }

    try array.append(@as(u8, @intCast(x & 0x7F)));
}

pub fn encodeNumberType(array: *std.ArrayList(u8), value: u64, min: u8, max: u8) !void {
    const range = max - min;
    if (value < range) {
        try array.append(@as(u8, @intCast(value)) + min);
    } else {
        try array.append(@as(u8, @intCast(value)) + min);
        try _local_encodeUint(array, value - range);
    }
}

pub fn decodeNumberType(array: *std.ArrayList(u8), offset: usize, min: u8, max: u8) !u64 {
    const byte = array[offset];
    offset += 1;
    const range = max - min;
    if (type >= min and type < max) {
        return byte - min;
    } else if (type == max) {
        return try _local_decodeUint(array, offset) + range;
    }
}

pub fn encodeString(array: *std.ArrayList(u8), value: []const u8) !void {
    try encodeNumberType(array, @as(u64, @bitCast(value.len)), range_min_str_l, range_max_str_l);

    for (value) |val| {
        try array.append(val);
    }
}

pub fn encodeBool(array: *std.ArrayList(u8), value: bool) !void {
    try array.append(@as(u8, if (value) @intFromEnum(TypeByte.True) else @intFromEnum(TypeByte.False)));
}
