const std = @import("std");

// Simple "Hello World" for WASM
export fn add(a: i32, b: i32) i32 {
    return a + b;
}

export fn greet() void {
    // In real WASM, this string will be in the binary!
    const message = "שלום עולם Hello World פורנוגרפיה";
    _ = message;
}

// String that should appear in WASM
const GLOBAL_MESSAGE: []const u8 = "הימורים קזינו מבוגרים";

export fn getMessage() [*]const u8 {
    return GLOBAL_MESSAGE.ptr;
}
