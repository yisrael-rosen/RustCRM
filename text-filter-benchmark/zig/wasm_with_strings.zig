// WASM with actual string data that won't be optimized out

// Export a global with our string data
export const STRING_DATA: [100]u8 = blk: {
    var data: [100]u8 = undefined;

    // Hebrew strings that should appear in WASM
    const msg1 = "שלום עולם Hello";
    const msg2 = "פורנוגרפיה";
    const msg3 = "הימורים קזינו";

    var offset: usize = 0;

    // Copy strings into data
    for (msg1) |c| {
        data[offset] = c;
        offset += 1;
    }
    data[offset] = ' ';
    offset += 1;

    for (msg2) |c| {
        data[offset] = c;
        offset += 1;
    }
    data[offset] = ' ';
    offset += 1;

    for (msg3) |c| {
        data[offset] = c;
        offset += 1;
    }

    // Fill rest with zeros
    while (offset < 100) : (offset += 1) {
        data[offset] = 0;
    }

    break :blk data;
};

export fn getStringData() [*]const u8 {
    return &STRING_DATA;
}

export fn add(a: i32, b: i32) i32 {
    return a + b;
}
