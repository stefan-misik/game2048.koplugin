local Blitbuffer = require("ffi/blitbuffer")
local _ = require("gettext")


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
}
