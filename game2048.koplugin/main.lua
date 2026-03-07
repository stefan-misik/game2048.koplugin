--[[--
This is a game inspired by 2048

@module koplugin.Game2048
--]]--

local Blitbuffer = require("ffi/blitbuffer")
local BottomContainer = require("ui/widget/container/bottomcontainer")
local ButtonTable = require("ui/widget/buttontable")
local CenterContainer = require("ui/widget/container/centercontainer")
local ConfirmBox = require("ui/widget/confirmbox")
local DataStorage = require("datastorage")
local Device = require("device")
local FocusManager = require("ui/widget/focusmanager")
local Font = require("ui/font")
local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local InfoMessage = require("ui/widget/infomessage")
local InputContainer = require("ui/widget/container/inputcontainer")
local LuaSettings = require("luasettings")
local OverlapGroup = require("ui/widget/overlapgroup")
local Size = require("ui/size")
local TextWidget = require("ui/widget/textwidget")
local TitleBar = require("ui/widget/titlebar")
local UIManager = require("ui/uimanager")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local logger = require("logger")
local _ = require("gettext")

local Input = Device.input
local Screen = Device.screen

local Game2048Widget = require("ui.widget.game2048widget")
local ScoreBoardWidget = require("ui.widget.scoreboardwidget")
local GameBoard = require("gameboard")
local History = require("history")


---@class Game2048Storage Game settings
---@field name string
---@field _settings LuaSettings
local Game2048Storage = {
    -- Settings name
    name = "unknown_name",
    _settings = nil,
}
Game2048Storage.__index = Game2048Storage

function Game2048Storage:new(obj)
    obj = obj or { };
    setmetatable(obj, self)

    obj._settings = LuaSettings:open(DataStorage:getSettingsDir() .. "/" .. obj.name .. ".lua")

    return obj
end

--- Save state
---@param state Game2048State  Game state
function Game2048Storage:saveState(state)
    local state_dump = {
        history = state.history:save(),
    }
    self._settings:saveSetting("state", state_dump)
end

--- Read state
---@param state Game2048State  Game state
function Game2048Storage:readState(state)
    local state_dump = self._settings:readSetting("state")
    if state_dump then
        return state.history:read(state_dump.history)
    end
    return false
end

function Game2048Storage:flush()
    self._settings:flush()
end


---@class Game2048State
---@field history History
---@field board GameBoard
---@field delayed_tile_placement function
local Game2048State = {
    history = nil,
    board = nil,
}
Game2048State.__index = Game2048State

function Game2048State:new(obj)
    obj = obj or {
        board = GameBoard:new(),
        history = History:new(),
        delayed_tile_placement = nil,
    }
    setmetatable(obj, self)

    -- Initialize
    obj:reset()
    return obj
end

function Game2048State:reset()
    self.history:clear()
    self.board:reset()
    -- Place first tile
    self.board:placeNew()
    self:pushToHistory()
end

function Game2048State:pushToHistory()
    self.history:push(self:_captureState())
end

function Game2048State:pullFromHistory()
    local state = self.history:current()
    if state then
        self:_applyState(state)
        return true
    end
    return false
end

function Game2048State:historyUndo()
    if self.delayed_tile_placement then
        return false
    end
    local state = self.history:undo()
    if not state then
        return false
    end
    return self:_applyState(state)
end

function Game2048State:historyRedo()
    if self.delayed_tile_placement then
        return false
    end
    local state = self.history:redo()
    if not state then
        return false
    end
    return self:_applyState(state)
end

function Game2048State:_captureState()
    return {
        board = self.board:getFieldCopy(),
    }
end

function Game2048State:_applyState(state)
    if not self.board:setFieldCopy(state.board) then
        return false
    end
    return true
end


-- Main game screen (only shown when selected from menu)
local Game2048Screen = FocusManager:extend{
    title = "2048",

    -- Game state object
    state = nil,
    -- Function called when game screen wants to be closed
    close_cb = nil,
}

function Game2048Screen:init()
    self.dimen = Geom:new{
        w = Screen:getWidth(),
        h = Screen:getHeight(),
    }
    self.covers_fullscreen = true -- hint for UIManager:_repaint()
    self.layout = {}

    self._title_bar = TitleBar:new{
        fullscreen = true,
        title = self.title,
        left_icon = "appbar.menu",
        left_icon_tap_callback = function() end,
        close_callback = function() self:onClose() end,
        show_parent = self,
    }

    self._body = VerticalGroup:new{
        align = "center",
    }

    -- Buttons
    self._buttons = ButtonTable:new{
        width = self.dimen.w,
        show_parent = self,
        buttons = {
            {
                {
                    text = _("New game"),
                    width = Screen:scaleBySize(200),
                    callback = function()
                        UIManager:show(ConfirmBox:new{
                            text = _("Start a new game?"),
                            ok_callback = function()
                                self:resetGame()
                            end,
                        })
                    end,
                },
                {
                    icon = "chevron.left",
                    enabled_func = function()
                        return self.state.history:canUndo()
                    end,
                    width = Screen:scaleBySize(80),
                    callback = function()
                        self:onUndo()
                    end,
                },
                {
                    icon = "chevron.right",
                    enabled_func = function()
                        return self.state.history:canRedo()
                    end,
                    width = Screen:scaleBySize(80),
                    callback = function()
                        self:onRedo()
                    end,
                },
            },
        },
    }
    self:mergeLayoutInVertical(self._buttons)

    local SCREEN_PADDING = Screen:scaleBySize(20)

    self._body[#self._body+1] = self._buttons

    self._body[#self._body+1] = VerticalSpan:new{
        width = SCREEN_PADDING,
    }

    self._info_board = {
        score = ScoreBoardWidget:new{
            name = _("Score"),
            value = "0",
        },
        best = ScoreBoardWidget:new{
            name = _("Best Score"),
            value = "1942506999",
        },
        moves = ScoreBoardWidget:new{
            name = _("Move"),
            value = "0",
        },
        retries = ScoreBoardWidget:new{
            name = _("Retries"),
            value = "0",
        },
        timer = ScoreBoardWidget:new{
            name = _("Timer"),
            value = "0",
        },
    }

    self._body[#self._body+1] = HorizontalGroup:new{
        self._info_board.score,
        HorizontalSpan:new{
            width = SCREEN_PADDING,
        },
        self._info_board.best,
        HorizontalSpan:new{
            width = SCREEN_PADDING,
        },
        self._info_board.moves,
    }

    self._body[#self._body+1] = VerticalSpan:new{
        width = SCREEN_PADDING,
    }

    self._body[#self._body+1] = HorizontalGroup:new{
        self._info_board.retries,
        HorizontalSpan:new{
            width = 2 * SCREEN_PADDING + self._info_board.best.width,
        },
        self._info_board.timer,
    }

    self._body[#self._body+1] = VerticalSpan:new{
        width = SCREEN_PADDING,
    }

    -- Game widget
    self._game_widget = Game2048Widget:new{
        width = self.dimen.w * 0.7,
        show_parent = self,
        face = Font:getFace("tfont", 35),
        numbers = self.state.board:getField(),
        move_handler = function(dir) self:onGame2048Move(dir) end,
    }

    self._body[#self._body+1] = self._game_widget

    self.layout[#self.layout+1] = {self._game_widget}

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
            self._title_bar,
            self._body,
        }
    }

    if Device:hasKeys() then
        self.key_events.Close = { { Input.group.Back } }
        self.key_events.Undo = { { Input.group.PgBack } }
        self.key_events.Redo = { { Input.group.PgFwd } }
    end

    self:refocusWidget()
    self:moveFocusTo(1, 2)
    if not Device:hasDPad() then
        -- Activate the main widget, so that it looks consistent when device has no way of activating it via keyboard
        self._game_widget:setActive(true)
    end
end

function Game2048Screen:resetGame()
    local state = self.state
    state:reset()
    self._game_widget:setNumbers(state.board:getField())
    UIManager:setDirty(self, "ui", self._buttons.dimen)
end

function Game2048Screen:onClose()
    if self.close_cb then
        self.close_cb()
    end
    return true
end

function Game2048Screen:onGame2048Move(dir)
    local state = self.state
    if not state.delayed_tile_placement then
        local board = state.board
        if board:shift(dir) then
            self._game_widget:setNumbers(board:getField())
            -- delay placing new tile
            state.delayed_tile_placement = function ()
                state.delayed_tile_placement = nil
                board:placeNew()
                self._game_widget:setNumbers(board:getField())
                state:pushToHistory()
                UIManager:setDirty(self, "ui", self._buttons.dimen)
            end
            UIManager:scheduleIn(0.1, state.delayed_tile_placement)
        end
    end
    return true
end

function Game2048Screen:onUndo()
    local state = self.state
    state:historyUndo()
    self._game_widget:setNumbers(state.board:getField())
    UIManager:setDirty(self, "ui", self._buttons.dimen)
    return true
end

function Game2048Screen:onRedo()
    local state = self.state
    state:historyRedo()
    self._game_widget:setNumbers(state.board:getField())
    UIManager:setDirty(self, "ui", self._buttons.dimen)
    return true
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

    -- Initialize variables
    self.screen = nil
    self.state = Game2048State:new()

    self.storage = Game2048Storage:new{
        name = self.name,
    }
    if self.storage:readState(self.state) then
        self.state:pullFromHistory()
    end

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
        state = self.state,
        close_cb = function() self:closeScreen() end,
    }
    UIManager:show(self.screen)
end

function Game2048:closeScreen()
    UIManager:close(self.screen)
    self.screen:free()
    self.screen = nil
    self.storage:saveState(self.state)
    self.storage:flush()
end

return Game2048