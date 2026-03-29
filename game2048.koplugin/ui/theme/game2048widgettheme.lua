local Blitbuffer = require("ffi/blitbuffer")
local _ = require("gettext")


-- This file defines the themes available for the game. Each theme is a table with the following keys:
-- - id: a unique identifier for the theme (string)
-- - name: a human-readable name for the theme (string)
-- - palette: a table of colors used for the tiles, where the index corresponds to the tile value (1 for 2, 2 for 4,
--   etc.). The colors can either be 8-bit grayscale or 32-bit RGBA, however, they must be of the same type within a
--   theme.
return {
    {
        id = "default",
        name = _("Default"),
        palette = {
            Blitbuffer.COLOR_GRAY_E,
            Blitbuffer.COLOR_LIGHT_GRAY,
            Blitbuffer.COLOR_GRAY,
            Blitbuffer.COLOR_GRAY_9,
            Blitbuffer.COLOR_GRAY_7,
            Blitbuffer.COLOR_GRAY_6,
            Blitbuffer.COLOR_GRAY_4,
            Blitbuffer.COLOR_GRAY_3,
            Blitbuffer.COLOR_GRAY_2,
            Blitbuffer.COLOR_GRAY_1,
            Blitbuffer.COLOR_BLACK,
        },
    },
    {
        id = "all_black",
        name = _("All Black"),
        palette = {
            Blitbuffer.COLOR_BLACK,
        },
    },
    {
        id = "all_white",
        name = _("All White"),
        palette = {
            Blitbuffer.COLOR_WHITE,
        },
    },
    {
        id = "high_contrast",
        name = _("High Contrast"),
        palette = {
            Blitbuffer.COLOR_WHITE,
            Blitbuffer.COLOR_WHITE,
            Blitbuffer.COLOR_WHITE,
            Blitbuffer.COLOR_WHITE,
            Blitbuffer.COLOR_WHITE,
            Blitbuffer.COLOR_WHITE,
            Blitbuffer.COLOR_WHITE,
            Blitbuffer.COLOR_BLACK,
        },
    },
    {
        id = "classic",
        name = _("Classic 2048 (color)"),
        palette = {
            Blitbuffer.ColorRGB32(0xEE, 0xE4, 0xDA, 0xFF),
            Blitbuffer.ColorRGB32(0xED, 0xE0, 0xC8, 0xFF),
            Blitbuffer.ColorRGB32(0xF2, 0xB1, 0x79, 0xFF),
            Blitbuffer.ColorRGB32(0xF5, 0x95, 0x63, 0xFF),
            Blitbuffer.ColorRGB32(0xF6, 0x7C, 0x5F, 0xFF),
            Blitbuffer.ColorRGB32(0xF6, 0x5E, 0x3B, 0xFF),
            Blitbuffer.ColorRGB32(0xED, 0xCF, 0x72, 0xFF),
            Blitbuffer.ColorRGB32(0xED, 0xCC, 0x61, 0xFF),
            Blitbuffer.ColorRGB32(0xED, 0xC8, 0x50, 0xFF),
            Blitbuffer.ColorRGB32(0xED, 0xC5, 0x3F, 0xFF),
            Blitbuffer.ColorRGB32(0xED, 0xC2, 0x2E, 0xFF),
        },
    },
    {
        id = "ocean",
        name = _("Ocean (color)"),
        palette = {
            Blitbuffer.ColorRGB32(0xD6, 0xEA, 0xF8, 0xFF),
            Blitbuffer.ColorRGB32(0xAE, 0xD6, 0xF1, 0xFF),
            Blitbuffer.ColorRGB32(0x85, 0xC1, 0xE9, 0xFF),
            Blitbuffer.ColorRGB32(0x5D, 0xAD, 0xE2, 0xFF),
            Blitbuffer.ColorRGB32(0x34, 0x98, 0xDB, 0xFF),
            Blitbuffer.ColorRGB32(0x2E, 0x86, 0xC1, 0xFF),
            Blitbuffer.ColorRGB32(0x28, 0x74, 0xA6, 0xFF),
            Blitbuffer.ColorRGB32(0x21, 0x61, 0x8C, 0xFF),
            Blitbuffer.ColorRGB32(0x1B, 0x4F, 0x72, 0xFF),
            Blitbuffer.ColorRGB32(0x15, 0x43, 0x60, 0xFF),
            Blitbuffer.ColorRGB32(0x0B, 0x2F, 0x45, 0xFF),
        },
    },
    {
        id = "forest",
        name = _("Forest (color)"),
        palette = {
            Blitbuffer.ColorRGB32(0xD5, 0xF5, 0xE3, 0xFF),
            Blitbuffer.ColorRGB32(0xAB, 0xEB, 0xC6, 0xFF),
            Blitbuffer.ColorRGB32(0x82, 0xE0, 0xAA, 0xFF),
            Blitbuffer.ColorRGB32(0x58, 0xD6, 0x8D, 0xFF),
            Blitbuffer.ColorRGB32(0x2E, 0xCC, 0x71, 0xFF),
            Blitbuffer.ColorRGB32(0x28, 0xB4, 0x63, 0xFF),
            Blitbuffer.ColorRGB32(0x23, 0x9B, 0x56, 0xFF),
            Blitbuffer.ColorRGB32(0x1E, 0x84, 0x49, 0xFF),
            Blitbuffer.ColorRGB32(0x19, 0x6F, 0x3D, 0xFF),
            Blitbuffer.ColorRGB32(0x14, 0x5A, 0x32, 0xFF),
            Blitbuffer.ColorRGB32(0x0E, 0x45, 0x25, 0xFF),
        },
    },
    {
        id = "sunset",
        name = _("Sunset (color)"),
        palette = {
            Blitbuffer.ColorRGB32(0xFD, 0xEB, 0xD0, 0xFF),
            Blitbuffer.ColorRGB32(0xFA, 0xD7, 0xA0, 0xFF),
            Blitbuffer.ColorRGB32(0xF8, 0xC4, 0x71, 0xFF),
            Blitbuffer.ColorRGB32(0xF5, 0xB0, 0x41, 0xFF),
            Blitbuffer.ColorRGB32(0xF3, 0x9C, 0x12, 0xFF),
            Blitbuffer.ColorRGB32(0xE6, 0x7E, 0x22, 0xFF),
            Blitbuffer.ColorRGB32(0xD3, 0x54, 0x00, 0xFF),
            Blitbuffer.ColorRGB32(0xC0, 0x39, 0x2B, 0xFF),
            Blitbuffer.ColorRGB32(0xA9, 0x32, 0x26, 0xFF),
            Blitbuffer.ColorRGB32(0x92, 0x2B, 0x21, 0xFF),
            Blitbuffer.ColorRGB32(0x7B, 0x24, 0x1C, 0xFF),
        },
    },
    {
        id = "berry",
        name = _("Berry (color)"),
        palette = {
            Blitbuffer.ColorRGB32(0xF5, 0xEE, 0xF8, 0xFF),
            Blitbuffer.ColorRGB32(0xE8, 0xDA, 0xEF, 0xFF),
            Blitbuffer.ColorRGB32(0xD2, 0xB4, 0xDE, 0xFF),
            Blitbuffer.ColorRGB32(0xBB, 0x8F, 0xCE, 0xFF),
            Blitbuffer.ColorRGB32(0xA5, 0x69, 0xBD, 0xFF),
            Blitbuffer.ColorRGB32(0x8E, 0x44, 0xAD, 0xFF),
            Blitbuffer.ColorRGB32(0x7D, 0x3C, 0x98, 0xFF),
            Blitbuffer.ColorRGB32(0x6C, 0x34, 0x83, 0xFF),
            Blitbuffer.ColorRGB32(0x5B, 0x2C, 0x6F, 0xFF),
            Blitbuffer.ColorRGB32(0x4A, 0x23, 0x5A, 0xFF),
            Blitbuffer.ColorRGB32(0x3B, 0x1C, 0x47, 0xFF),
        },
    },
}
