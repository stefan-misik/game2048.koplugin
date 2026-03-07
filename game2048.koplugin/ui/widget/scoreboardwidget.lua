local BD = require("ui/bidi")
local Blitbuffer = require("ffi/blitbuffer")
local CenterContainer = require("ui/widget/container/centercontainer")
local Device = require("device")
local FocusManager = require("ui/widget/focusmanager")
local Font = require("ui/font")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local FrameContainer = require("ui/widget/container/framecontainer")
local Notification = require("ui/widget/notification")
local Size = require("ui/size")
local TextWidget = require("ui/widget/textwidget")
local UIManager = require("ui/uimanager")
local VerticalGroup = require("ui/widget/verticalgroup")
local Widget = require("ui/widget/widget")
local _ = require("gettext")

local Screen = Device.screen


local ScoreBoardWidget = Widget:extend{
    width = Screen:scaleBySize(130),
    face = Font:getFace("cfont", 20),
    show_parent = nil,

    name = "",
    value = "",
}

function ScoreBoardWidget:init()
    self.frame = FrameContainer:new{
        background = Blitbuffer.COLOR_WHITE,
        color = Blitbuffer.COLOR_BLACK,
        radius = Size.radius.window,
        bordersize = Size.border.thin,
        padding = Size.padding.default,
    }

    local name_label = TextWidget:new{
        text = self.name,
        face = self.face,
        bold = true,
    }
    local value_label = TextWidget:new{
        text = self.value,
        face = self.face,
        bold = false,
    }

    local text_max_width = self.width - (2 * (self.frame.padding + self.frame.bordersize))
    self.content = VerticalGroup:new{
        CenterContainer:new{
            dimen = Geom:new{ w = text_max_width, h = name_label:getSize().h, },
            ignore = "height",
            name_label
        },
        CenterContainer:new{
            dimen = Geom:new{ w = text_max_width, h = value_label:getSize().h, },
            ignore = "height",
            value_label,
        },
    }

    self.frame[1] = self.content
    self[1] = self.frame
    self._value_label = value_label
end

function ScoreBoardWidget:paintTo(bb, x, y)
    if not self.dimen then
        local content_size = self[1]:getSize()
        self.dimen = Geom:new{
            x = x, y = y,
            w = content_size.w, h = content_size.h
        }
    end
    self[1]:paintTo(bb, x, y)
end

function ScoreBoardWidget:getSize()
    return self[1]:getSize()
end

function ScoreBoardWidget:setValue(text)
    self._value_label:setText(text)
    if self.dimen then
        -- Only redraw once the position is known
        UIManager:setDirty(self.show_parent or self, "fast", self.dimen)
    end
end

return ScoreBoardWidget