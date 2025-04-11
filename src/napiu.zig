const c = @import("napi.zig");

const std = @import("std");
const assert = std.debug.assert;

const allocator = std.heap.c_allocator;

pub const napi_undefined = 0;
pub const napi_null = 1;
pub const napi_boolean = 2;
pub const napi_number = 3;
pub const napi_string = 4;
pub const napi_symbol = 5;
pub const napi_object = 6;
pub const napi_function = 7;
pub const napi_external = 8;
pub const napi_bigint = 9;

pub const NapiErrors = error{ BufferCast, InvalidArgv, InvalidValue, CreateValue, CheckValue, TooLarge };

pub fn write_from_buffer(buffer: []u8, array: *std.ArrayList(u8)) !void {
    for (buffer) |el| try array.append(el);
}

pub fn buffer_from_arraylist(env: c.napi_env, buffer: std.ArrayList(u8)) !c.napi_value {
    var data: ?*anyopaque = null;
    var result: c.napi_value = undefined;

    if (c.napi_create_buffer(env, buffer.items.len, &data, &result) != 0) {
        _ = c.napi_throw_error(env, null, "Unable to get buffer info");
        return NapiErrors.BufferCast;
    }

    const buf: []u8 = @as([*]u8, @ptrCast(data))[0..buffer.items.len];

    var index: usize = 0;
    for (buffer.items) |item| {
        buf[index] = item;
        index += 1;
    }

    return result;
}

pub fn get_argv(env: c.napi_env, info: c.napi_callback_info, argv: []c.napi_value) !void {
    var argc: usize = argv.len;

    if (c.napi_get_cb_info(env, info, &argc, @ptrCast(argv.ptr), null, null) != c.napi_ok) {
        _ = c.napi_throw_error(env, null, "Unable to get arguments");
        return NapiErrors.InvalidArgv;
    }

    if (argc != argv.len) {
        _ = c.napi_throw_error(env, null, "Unexpected number of arguments");
        return NapiErrors.InvalidArgv;
    }
}

pub fn get_int32(env: c.napi_env, value: c.napi_value) !i32 {
    var result: i32 = undefined;

    if (c.napi_get_value_int32(env, value, &result) != 0) {
        _ = c.napi_throw_error(env, null, "Expected int32 number");
        return NapiErrors.InvalidValue;
    }

    return result;
}

pub fn get_int64(env: c.napi_env, value: c.napi_value) !i64 {
    var result: i64 = undefined;

    if (c.napi_get_value_int64(env, value, &result) != 0) {
        _ = c.napi_throw_error(env, null, "Expected int64 number");
        return NapiErrors.InvalidValue;
    }

    return result;
}

pub fn get_string(env: c.napi_env, value: c.napi_value) ![]u8 {
    const bufSize: usize = 1024;
    var buf: [bufSize]u8 = undefined;
    var result: usize = 0;

    if (c.napi_get_value_string_utf8(env, value, &buf, bufSize, &result) != 0) {
        _ = c.napi_throw_error(env, null, "Expected string");
        return NapiErrors.InvalidValue;
    }

    return buf[0..result];
}

pub fn get_buffer(env: c.napi_env, value: c.napi_value) ![]u8 {
    var data: [*]u8 = undefined;
    var length: usize = undefined;

    if (c.napi_get_buffer_info(env, value, @as(*?*anyopaque, @ptrCast(&data)), &length) != 0) {
        _ = c.napi_throw_error(env, null, "Expected buffer");
        return NapiErrors.InvalidValue;
    }

    return data[0..length];
}

pub fn get_array_length(env: c.napi_env, value: c.napi_value) !u32 {
    var result: u32 = undefined;

    if (c.napi_get_array_length(env, value, &result) != 0) {
        _ = c.napi_throw_error(env, null, "Cannot get array length");
        return NapiErrors.InvalidValue;
    }

    return result;
}

pub fn get_double(env: c.napi_env, value: c.napi_value) !f64 {
    var result: f64 = undefined;

    if (c.napi_get_buffer_info(env, value, &result) != 0) {
        _ = c.napi_throw_error(env, null, "Expected Double");
        return NapiErrors.InvalidValue;
    }

    return result;
}

pub fn get_boolean(env: c.napi_env, value: c.napi_value) !bool {
    var result: bool = undefined;

    if (c.napi_get_value_bool(env, value, &result) != 0) {
        _ = c.napi_throw_error(env, null, "Expected boolean");
        return NapiErrors.InvalidValue;
    }

    return result;
}

pub fn get_int128(env: c.napi_env, value: c.napi_value) !i128 {
    var sign: c_int = 0;
    var wordc: usize = 0;
    var words: [2]u64 = undefined;

    if (c.napi_get_value_bigint_words(env, value, &sign, &wordc, &words) != 0) {
        _ = c.napi_throw_error(env, null, "Invalid BigInt");
        return NapiErrors.InvalidValue;
    }

    if (wordc > 2) {
        _ = c.napi_throw_error(env, null, "Too large bigint, support only 128bits");
        return NapiErrors.TooLarge;
    }

    const lo = words[0];
    const hi = if (wordc > 1) words[1] else 0;

    const unsigned = (@as(u128, hi) << 64) | @as(u128, lo);

    return if (sign != 0)
        -@as(i128, @bitCast(unsigned))
    else
        @as(i128, @bitCast(unsigned));
}

pub fn create_int64(env: c.napi_env, value: i64) !c.napi_value {
    var result: c.napi_value = undefined;

    if (c.napi_create_int64(env, value, &result) != 0) {
        _ = c.napi_throw_error(env, null, "Unable to create int64");
        return NapiErrors.CreateValue;
    }

    return result;
}

pub fn create_int128(env: c.napi_env, value: i128) !c.napi_value {
    const sign_bit: c_int = value < 0;
    const abs_val: u128 = if (sign_bit) @as(u128, @bitCast(-value)) else @as(u128, @bitCast(value));

    const low = @as(u64, abs_val & 0xFFFFFFFFFFFFFFFF);
    const high = @as(u64, abs_val >> 64);

    const word_count = if (high != 0) 2 else 1;

    var words: [2]u64 = .{ low, high };

    var result: c.napi_value = undefined;

    if (c.napi_create_bigint_words(env, sign_bit, word_count, &words, &result) != c.napi_ok)
        return error.BigIntCreateFailed;

    return result;
}

pub fn type_of(env: c.napi_env, value: c.napi_value) !c.napi_valuetype {
    var valuetype: c.napi_valuetype = undefined;

    if (c.napi_typeof(env, value, &valuetype) != 0) {
        _ = c.napi_throw_error(env, null, "Unable to check type");
        return NapiErrors.CheckValue;
    }

    return valuetype;
}

pub fn is_object(value: c.napi_valuetype) !bool {
    return value == napi_object;
}

pub fn is_array(env: c.napi_env, value: c.napi_value) !bool {
    var result: bool = undefined;
    if (c.napi_is_array(env, value, &result) != 0) {
        _ = c.napi_throw_error(env, null, "Unable to check type");
        return NapiErrors.CheckValue;
    }

    return result;
}
