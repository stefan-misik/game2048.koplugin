--[[--
This is a game inspired by 2048

@module koplugin.Game2048
--]]--

local Blitbuffer = require("ffi/blitbuffer")
local CenterContainer = require("ui/widget/container/centercontainer")
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
local logger = require("logger")
local _ = require("gettext")

local Input = Device.input
local Screen = Device.screen

local Game2048Widget = require("ui.widget.game2048widget")


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
            w = self.dimen.w,
            h = self.dimen.h - self.title_bar:getSize().h,
        }
    }

    -- Game widget
    self._game_widget = Game2048Widget:new{
        width = self.body.dimen.w * 0.8,
        numbers = {
            0, 1, 2, 3,
            4, 5, 6, 7,
            8, 9, 10, 11,
            20, 26, 27, 28,
        },
        move_handler = function(dir) self:onGame2048Move(dir) end,
        --numbers = {
        --    0, 1, 2,
        --    4, 5, 6,
        --    20, 26, 28,
        --},
        --numbers = {
        --    0, 1, 2, 3,
        --    4, 5, 6, 7,
        --    8, 9, 10, 11,
        --    20, 26, 27, 28,
        --    15, 16, 17, 18,
        --    19, 20, 21, 22, 23
        --},
    }

    self.body[1] = CenterContainer:new{
        ignore = 'height',
        dimen = self.body.dimen,
        self._game_widget
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

    local layout = {}
    for n = 1,#self.body do
        layout[n] = self.body[n]
    end
    self.layout = layout
    self:refocusWidget()
end

function Game2048Screen:onClose()
    self.plugin:closeScreen()
    return true
end

function Game2048Screen:onGame2048Move(dir)
    logger.dbg("2048 Move: ", dir)
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

function Game2048:closeScreen()
    UIManager:close(self.screen)
    self.screen:free()
    self.screen = nil
end

return Game2048