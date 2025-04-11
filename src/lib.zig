const c = @import("napi.zig");
const ctx = @import("ctx.zig");
const std = @import("std");
const napiu = @import("napiu.zig");
const value = @import("value.zig");
const cast = @import("cast.zig");
const block = @import("block.zig");

const allocator = std.heap.c_allocator;

fn wrapper_encoder(env: c.napi_env, info: c.napi_callback_info) !c.napi_value {
    var argv: [1]c.napi_value = undefined;
    napiu.get_argv(env, info, argv[0..]) catch {
        return null;
    };

    const block_of_data = try cast.napi_to_block(env, argv[0]);

    var buffer = std.ArrayList(u8).init(allocator);

    var context = ctx.ContextEncode{ .buffer = &buffer, .offset = 0 };

    try block.Block.encode(block_of_data, &context);

    return try napiu.buffer_from_arraylist(env, buffer);
}

fn encode(env: c.napi_env, info: c.napi_callback_info) callconv(.C) c.napi_value {
    return wrapper_encoder(env, info) catch {
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
