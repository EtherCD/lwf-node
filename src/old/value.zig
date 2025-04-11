const c = @import("c.zig");
const utils = @import("utils.zig");
const vars = @import("vars.zig");
const std = @import("std");

pub fn encode(env: c.napi_env, value: c.napi_value, buffer: *std.ArrayList(u8)) !void {
    const elemtype = try utils.type_of(env, value);

    switch (elemtype) {
        utils.napi_boolean => {
            try vars.encodeBool(buffer, try utils.get_boolean(env, value));
        },
        utils.napi_number => {
            const val = try utils.get_int64(env, value);
            if (val >= 0)
                try vars.encodeUint(buffer, @intCast(val))
            else {
                try buffer.append(@intFromEnum(vars.TypeByte.Int));
                try vars.encodeInt(buffer, val);
            }
        },
        utils.napi_string => {
            try vars.encodeString(buffer, try utils.get_string(env, value));
        },
        utils.napi_bigint => {
            try vars.encodeBigInt(buffer, try utils.get_int128(env, value));
        },
        utils.napi_null => {
            try buffer.append(@intFromEnum(vars.TypeByte.Null));
        },
        else => {
            _ = c.napi_throw_error(env, null, "Unsupported value type to encode as simple val.");
            return utils.NapiErrors.InvalidValue;
        },
    }
}

pub fn decode(env: c.napi_env, buffer: *std.ArrayList(u8), offset: usize) c.napi_value {
    _ = env; // autofix
    _ = buffer; // autofix
    _ = offset; // autofix

}
