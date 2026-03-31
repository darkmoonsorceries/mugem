// HarfBuzz C bindings for Mugem
const std = @import("std");

// Minimal HarfBuzz handle wrapper
pub const HbFont = opaque {};
pub const HbBuffer = opaque {};
pub const HbGlyphInfo = extern struct {
    codepoint: u32,
    cluster: u32,
};

// Stub implementations - will link to system HarfBuzz
pub extern "harfbuzz" fn hb_buffer_create() ?*HbBuffer;
pub extern "harfbuzz" fn hb_buffer_destroy(buffer: *HbBuffer) void;
pub extern "harfbuzz" fn hb_buffer_add_utf8(buffer: *HbBuffer, text: [*]const u8, len: c_int, item_offset: c_uint, item_length: c_int) void;
pub extern "harfbuzz" fn hb_buffer_set_direction(buffer: *HbBuffer, direction: c_int) void;

pub const HbDirection = enum(c_int) {
    ltr = 4,
    rtl = 5,
    ttb = 6,
    btt = 7,
};

// Tawhid: 5-7-12 as display constants
pub const TAWHID = struct {
    pub const FATIHA = 0; // Maximum verbosity
    pub const BAQARA = 1;
    pub const NAHL = 2;
    pub const TAKWIR = 3;
    pub const MUGETSU = 4; // Minimum verbosity
    pub const MIN_FIVES = [_]u8{5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60};
    pub const CHECKPOINTS = [_]u8{1, 2, 3, 4, 5, 6, 7};
};

// Variable-width cell for bidirectional text
pub const MugemCell = struct {
    grapheme: []const u8,
    script: Script,
    width: f32, // Variable! Not fixed to 1 or 2
    direction: Direction,
};

pub const Script = enum {
    latin, // LTR
    arabic, // RTL
    han, // Chinese
    hanja, // Japanese
    hiragana,
    katakana,
    hangul,
};

pub const Direction = enum {
    ltr, // English
    rtl, // Arabic
    ttb, // Japanese vertical (tategaki)
    unset,
};

/// Detect direction from first strong char
pub fn detectDirection(text: []const u8) Direction {
    for (text) |c| {
        // Arabic/Hebrew range
        if (c >= 0x0590 and c <= 0x08FF) return .rtl;
        // CJK (vertical default)
        if (c >= 0x3040 and c <= 0x309F) return .ltr; // Hiragana (can do TTB)
        if (c >= 0x4E00 and c <= 0x9FFF) return .ltr; // Han (context dependent)
    }
    return .ltr; // Default
}

/// Calculate variable width based on grapheme
pub fn calculateWidth(cell: MugemCell) f32 {
    return switch (cell.script) {
        .latin => 1.0,
        .arabic => 1.0, // Arabic ligatures may be wider
        .han => 2.0, // Traditional CJK width
        .hanja => 2.0,
        .hiragana => 1.0,
        .katakana => 1.0,
        .hangul => 2.0,
    };
}
