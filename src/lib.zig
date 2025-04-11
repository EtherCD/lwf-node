const c = @import("napi.zig");
const ctx = @import("ctx.zig");
const std = @import("std");
const napiu = @import("napiu.zig");
const value = @import("value.zig");

const allocator = std.heap.c_allocator;

fn wrapper_encoder(env: c.napi_env, info: c.napi_callback_info) !c.napi_value {
    var argv: [1]c.napi_value = undefined;
    napiu.get_argv(env, info, argv[0..]) catch {
        return null;
    };

    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();
    var context = ctx.ContextEncode{
        .buffer = &buffer,
        .offset = 0,
    };

    const val = value.Value{ .int = try napiu.get_int64(env, argv[0]) };

    try value.Value.encode(val, &context);

    return try napiu.buffer_from_arraylist(env, buffer);
}

fn wrapper_decode(env: c.napi_env, info: c.napi_callback_info) !c.napi_value {
    var argv: [1]c.napi_value = undefined;
    napiu.get_argv(env, info, argv[0..]) catch {
        return null;
    };

    const buffer = try napiu.get_buffer(env, argv[0]);
    var offset: usize = 0;

    var context = ctx.ContextDecode{ .buffer = buffer, .offset = &offset };

    const val = try value.Value.decode(&context);

    return try napiu.create_int64(env, @as(i64, @bitCast(val.int)));
}

fn encode(env: c.napi_env, info: c.napi_callback_info) callconv(.C) c.napi_value {
    return wrapper_encoder(env, info) catch {
        return null;
    };
}

fn decode(env: c.napi_env, info: c.napi_callback_info) callconv(.C) c.napi_value {
    return wrapper_decode(env, info) catch {
        return null;
    };
}

export fn napi_register_module_v1(env: c.napi_env, exports: c.napi_value) c.napi_value {
    const funcs = [_]struct {
        name: [*c]const u8,
        cb: c.napi_callback,
    }{
        .{ .name = "encodeInt64", .cb = encode },
        .{ .name = "decodeInt64", .cb = decode },
    };

    for (funcs) |f| {
        var fn_val: c.napi_value = undefined;
        _ = c.napi_create_function(env, null, 0, f.cb, null, &fn_val);
        _ = c.napi_set_named_property(env, exports, f.name, fn_val);
    }

    return exports;
}
