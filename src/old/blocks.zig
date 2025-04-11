const c = @import("c.zig");
const utils = @import("utils.zig");
const vars = @import("vars.zig");
const std = @import("std");
const valuelib = @import("value.zig");

const allocator = std.heap.c_allocator;

pub fn encode(env: c.napi_env, value: c.napi_value) !c.napi_value {
    const valuetype = try utils.type_of(env, value);

    var byte_buffer = std.ArrayList(u8).init(allocator);
    defer byte_buffer.deinit();

    if (valuetype == utils.napi_object) {
        var is_array: bool = false;
        _ = c.napi_is_array(env, value, &is_array);

        if (is_array) {
            var length: u32 = 0;
            _ = c.napi_get_array_length(env, value, &length);

            var i: u32 = 0;
            while (i < length) : (i += 1) {
                var elem: c.napi_value = undefined;
                _ = c.napi_get_element(env, value, i, &elem);

                try valuelib.encode(env, elem, &byte_buffer);
            }
        } else {
            _ = c.napi_throw_error(env, null, "Value must be Array.");
            return null;
        }
    } else {
        _ = c.napi_throw_error(env, null, "Value must be Object.");
        return null;
    }

    const buffer = utils.buffer_from_arraylist(env, byte_buffer);

    return buffer;
}
