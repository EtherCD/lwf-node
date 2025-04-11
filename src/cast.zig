const c = @import("napi.zig");
const std = @import("std");
const value = @import("value.zig");
const napiu = @import("napiu.zig");
const block = @import("block.zig");

pub const CastError = error{ ObjectCast, UnreachableValue };

const allocator = std.heap.c_allocator;

pub fn napi_to_value(napi_env: c.napi_env, napi_value: c.napi_value) !value.Value {
    const value_type = try napiu.type_of(napi_env, napi_value);

    if (try napiu.is_object(value_type)) {
        return CastError.ObjectCast;
    }

    return switch (value_type) {
        napiu.napi_bigint => value.Value{ .int128 = try napiu.get_int128(napi_env, napi_value) },
        napiu.napi_number => return value.Value{ .int = try napiu.get_int64(napi_env, napi_value) },
        napiu.napi_boolean => return value.Value{ .boolean = try napiu.get_boolean(napi_env, napi_value) },
        napiu.napi_null => return value.Value{ .nullable = true },
        napiu.napi_string => return value.Value{ .string = try napiu.get_string(napi_env, napi_value) },
        else => CastError.UnreachableValue,
    };
}

pub fn value_to_napi(napi_env: c.napi_env, internal_value: value.Value) !c.napi_value {
    return switch (internal_value) {
        .int => |v| try napiu.create_int64(napi_env, v),
        .int128 => |v| try napiu.create_int128(napi_env, v),
    };
}

pub fn napi_to_block(napi_env: c.napi_env, napi_value: c.napi_value) !block.Block {
    const value_type = try napiu.type_of(napi_env, napi_value);

    if (!(try napiu.is_object(value_type) and try napiu.is_array(napi_env, napi_value))) {
        return CastError.ObjectCast;
    }

    const length = try napiu.get_array_length(napi_env, napi_value);

    var values = try allocator.alloc(value.Value, length);

    var i: u32 = 0;
    while (i < length) : (i += 1) {
        var element: c.napi_value = undefined;
        if (c.napi_get_element(napi_env, napi_value, i, &element) != 0) {
            _ = c.napi_throw_error(napi_env, null, "Could not get array element");
            return error.InvalidArgument;
        }
        values[i] = try napi_to_value(napi_env, element);
    }

    return block.Block{ .index = 0, .values = values, .is_array = true };
}
