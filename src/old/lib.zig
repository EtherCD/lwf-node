const std = @import("std");
const assert = std.debug.assert;
const c = @import("c.zig");
const blocks = @import("blocks.zig");
const utils = @import("utils.zig");

const allocator = std.heap.c_allocator;

fn encode(env: c.napi_env, info: c.napi_callback_info) callconv(.C) c.napi_value {
    var argv: [1]c.napi_value = undefined;
    utils.get_argv(env, info, argv[0..]) catch {
        return null;
    };

    return blocks.encode(env, argv[0]) catch {
        return null;
    };
}

export fn napi_register_module_v1(env: c.napi_env, exports: c.napi_value) c.napi_value {
    const funcs = [_]struct {
        name: [*c]const u8,
        cb: c.napi_callback,
    }{
        .{ .name = "encodeArray", .cb = encode },
    };

    for (funcs) |f| {
        var fn_val: c.napi_value = undefined;
        _ = c.napi_create_function(env, null, 0, f.cb, null, &fn_val);
        _ = c.napi_set_named_property(env, exports, f.name, fn_val);
    }

    return exports;
}
