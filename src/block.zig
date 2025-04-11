const value = @import("value.zig");
const std = @import("std");
const ctx = @import("ctx.zig");
const variables = @import("variables.zig");

const allocator = std.heap.c_allocator;

pub const Block = struct {
    index: u64,
    values: []value.Value,
    is_array: bool,

    pub fn encode(self: Block, context: *ctx.ContextEncode) !void {
        try variables.Uint.encode(u64, context, self.index);
        if (self.is_array)
            try variables.Uint.encode(u64, context, self.values.len);
        for (self.values) |val| {
            try val.encode(context);
        }
    }
};
