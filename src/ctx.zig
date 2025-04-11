const std = @import("std");

pub const ContextEncode = struct {
    buffer: *std.ArrayList(u8),
    offset: usize,

    pub fn read(self: ContextEncode) u8 {
        const val = self.buffer.items[self.offset];
        self.offset += 1;
        return val;
    }

    pub fn peek(self: ContextEncode) u8 {
        return self.buffer.items[self.offset];
    }
};

pub const ContextDecode = struct {
    buffer: []u8,
    offset: *usize,

    pub fn read(self: ContextDecode) u8 {
        const val = self.buffer[self.offset.*];
        self.offset.* += 1;
        return val;
    }

    pub fn peek(self: ContextDecode) u8 {
        return self.buffer[self.offset.*];
    }
};
