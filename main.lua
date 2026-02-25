--[[--
This is a game inspired by 2048

@module koplugin.Game2048
--]]--

local Blitbuffer = require("ffi/blitbuffer")
local Device = require("device")
local FocusManager = require("ui/widget/focusmanager")
local VerticalGroup = require("ui/widget/verticalgroup")
local OverlapGroup = require("ui/widget/overlapgroup")
local Font = require("ui/font")
local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local InfoMessage = require("ui/widget/infomessage")
local InputContainer = require("ui/widget/container/inputcontainer")
local Size = require("ui/size")
local TextWidget = require("ui/widget/textwidget")
local TitleBar = require("ui/widget/titlebar")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _ = require("gettext")

local Input = Device.input
local Screen = Device.screen


-- Main game screen (only shown when selected from menu)
local Game2048Screen = FocusManager:extend{
    title = "2048",
}

function Game2048Screen:init()
    self.layout = {}
    self.dimen = Geom:new{
        w = Screen:getWidth(),
        h = Screen:getHeight(),
    }
    self.covers_fullscreen = true -- hint for UIManager:_repaint()

    -- Padding (maybe remove)
    self.body_hpad = Size.padding.large
    self.body_vpad = Size.padding.large

    self.title_bar = TitleBar:new{
        fullscreen = true,
        title = self.title,
        left_icon = "appbar.menu",
        left_icon_tap_callback = function() end,
        close_callback = function() self:onClose() end,
        show_parent = self,
    }

    self.body = OverlapGroup:new{
        dimen = Geom:new{
            w = self.dimen.w  - 2 * self.body_hpad,
            h = self.dimen.h - self.title_bar:getSize().h - 2 * self.body_vpad,
        }
    }

    -- Frame container ensures the background is drawn to solid color
    self[1] = FrameContainer:new{
        width = self.dimen.w,
        height = self.dimen.h,
        padding = 0,
        margin = 0,
        bordersize = 0,
        background = Blitbuffer.COLOR_WHITE,
        VerticalGroup:new{
            align = "center",
            background = Blitbuffer.COLOR_WHITE,
            self.title_bar,
            self.body,
        }
    }

    if Device:hasKeys() then
        self.key_events.Close = { { Input.group.Back } }
    end
end

function Game2048Screen:onClose()
    UIManager:close(self)
    self.plugin:onScreenClosed()
end


--[[--
    Game's widget container
--]]--
local Game2048 = WidgetContainer:extend{
    name = "game2048",
    is_doc_only = false,
}

function Game2048:init()
    self.ui.menu:registerToMainMenu(self)

    -- When debugging
    --UIManager:nextTick(function() self:showGame() end)
end

function Game2048:addToMainMenu(menu_items)
    menu_items.hello_world = {
        text = _("2048"),
        sorting_hint = "tools",
        callback = function()
            self:showGame()
        end,
    }
end

function Game2048:showGame()
    if self.screen then
        return
    end
    self.screen = Game2048Screen:new{
        plugin = self,
    }
    UIManager:show(self.screen)
end

function Game2048:onScreenClosed()
    self.screen = nil
end

return Game2048
