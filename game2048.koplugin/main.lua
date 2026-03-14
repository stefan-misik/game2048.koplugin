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


---Convert seconds into format hh:mm:ss
---@param seconds integer Seconds elapsed
---@return string formatted_time
local function timerToString(seconds)
    local ss = math.floor(seconds % 60)
    local mm = math.floor((seconds % 3600) / 60)
    local hh = math.floor(seconds / 3600)
    return string.format("%02d:%02d:%02d", hh, mm, ss)
end


---@class Game2048Storage Game settings
---@field name string
---@field _settings LuaSettings
local Game2048Storage = {
    -- Settings name
    name = "unknown_name",
}
Game2048Storage.__index = Game2048Storage

function Game2048Storage:new(obj)
    obj = obj or { };
    setmetatable(obj, self)

    obj:_init()
    return obj
end

function Game2048Storage:_init()
    self._settings = LuaSettings:open(DataStorage:getSettingsDir() .. "/" .. self.name .. ".lua")
    self.profile = self._settings:readSetting("profile") or "default"
end

--- Save state
---@param state Game2048State  Game state
function Game2048Storage:saveState(state)
    local state_dump = {
        history = state.history:save(),
        info = state.info:saveUntracked(),
    }
    self._settings:saveSetting("state_"..self.profile, state_dump)
end

--- Read state
---@param state Game2048State  Game state
function Game2048Storage:readState(state)
    local state_dump = self._settings:readSetting("state_"..self.profile)
    if state_dump then
        return state.history:read(state_dump.history) and
            state.info:readUntracked(state_dump.info)
    end
    return false
end

function Game2048Storage:flush()
    self._settings:flush()
end


---@class Game2048Info
---@field score integer
---@field best integer
---@field retries integer
---@field timer integer
---@field _start ?integer
local Game2048Info = { }
Game2048Info.__index = Game2048Info

function Game2048Info:new(obj)
    obj = obj or { }
    setmetatable(obj, self)

    -- Initialize
    obj:reset()
    return obj
end

function Game2048Info:reset()
    self.score = 0
    self.best = 0
    self.moves = 0
    self.retries = 0
    self.timer = 0
    self._start = nil
end

function Game2048Info:newGameReset()
    self.score = 0
    self.moves = 0
    self.retries = 0
    self.timer = 0
    self._start = nil
end

function Game2048Info:isRunning()
    return not not self._start
end

function Game2048Info:start()
    if not self._start then
        self._start = os.time()
    end
end

function Game2048Info:stop()
    self.timer = self:calculateCurrentTimer()
    self._start = nil
end

function Game2048Info:move(score)
    local new_score = self.score + score
    self.score = new_score
    self.best = math.max(self.best, new_score)
    self.moves = self.moves + 1
    if not self._start then
        self:start()
    end
end

function Game2048Info:calculateCurrentTimer()
    if not self._start then
        return self.timer
    end
    return self.timer + (os.time() - self._start)
end

function Game2048Info:saveUntracked()
    return {
        retries = self.retries,
        timer = self:calculateCurrentTimer(),
    }
end

function Game2048Info:readUntracked(dump)
    if not dump or not dump.retries or not dump.timer then
        return false
    end
    self.retries = dump.retries
    self.timer = dump.timer
    self._start = nil
    return true
end

function Game2048Info:save()
    return {
        score = self.score,
        best = self.best,
        moves = self.moves,
    }
end

function Game2048Info:read(dump)
    if not dump or not dump.score or not dump.best or not dump.moves then
        return false
    end
    self.score = dump.score
    self.best = dump.best
    self.moves = dump.moves
    return true
end


---@class Game2048State
---@field history History
---@field board GameBoard
---@field info Game2048Info
local Game2048State = { }
Game2048State.__index = Game2048State

function Game2048State:new(obj)
    obj = obj or { }
    setmetatable(obj, self)

    -- Initialize
    obj:_init()
    obj:reset()
    return obj
end

function Game2048State:_init()
    self.board = GameBoard:new()
    self.history = History:new()
    self.info = Game2048Info:new()
end

function Game2048State:reset()
    self.history:clear()
    self.board:reset()
    self.info:reset()
    -- Place first tile
    self.board:placeNew()
    self:pushToHistory()
end

function Game2048State:newGame()
    self.history:clear()
    self.board:reset()
    self.info:newGameReset()
    -- Place first tile
    self.board:placeNew()
    self:pushToHistory()
end

function Game2048State:move(dir)
    local score = 0
    local increment = function(new_tile)
        score = score + math.pow(2, new_tile)
    end
    if self.board:shift(dir, increment) then
        self.info:move(score)
        return true
    end
    return false
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
    local state = self.history:undo()
    if not state then
        return false
    end
    if not self:_applyState(state) then
        return false
    end
    self.info.retries = self.info.retries + 1
    return true
end

function Game2048State:historyRedo()
    local state = self.history:redo()
    if not state then
        return false
    end
    if not self:_applyState(state) then
        return false
    end
    self.info.retries = self.info.retries - 1
    return true
end

function Game2048State:_captureState()
    return {
        board = self.board:getFieldCopy(),
        info = self.info:save(),
    }
end

function Game2048State:_applyState(state)
    if not state or not self.board:setFieldCopy(state.board) or not self.info:read(state.info) then
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
    do
        local buttons = {
            {
                text = _("New game"),
                width = Screen:scaleBySize(200),
                callback = function()
                    UIManager:show(ConfirmBox:new{
                        text = _("Start a new game?"),
                        ok_callback = function()
                            self:newGame()
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
        }
        if Device:hasFrontlight() then
            table.insert(buttons, #buttons+1, {
                icon = "appbar.contrast",
                width = Screen:scaleBySize(80),
                callback = function()
                    -- Stop the timer when changing backlight, it will start automatically after next move
                    self.state.info:stop()
                    Device:showLightDialog()
                end,
            })
        end
        self._buttons = ButtonTable:new{
            width = self.dimen.w,
            show_parent = self,
            buttons = { buttons },
        }
    end
    self:mergeLayoutInVertical(self._buttons)

    local SCREEN_PADDING = Screen:scaleBySize(20)

    self._body[#self._body+1] = self._buttons

    self._body[#self._body+1] = VerticalSpan:new{
        width = SCREEN_PADDING,
    }

    self._info_board = {
        score = ScoreBoardWidget:new{
            name = _("Score"),
            value = "",
            show_parent = self,
        },
        best = ScoreBoardWidget:new{
            name = _("Best Score"),
            value = "",
            show_parent = self,
        },
        moves = ScoreBoardWidget:new{
            name = _("Move"),
            value = "",
            show_parent = self,
        },
        retries = ScoreBoardWidget:new{
            name = _("Retries"),
            value = "",
            show_parent = self,
        },
        timer = ScoreBoardWidget:new{
            name = _("Timer"),
            value = "",
            show_parent = self,
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

    -- Set first values
    self:_updateInfo()

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

function Game2048Screen:newGame()
    local state = self.state
    state:newGame()
    self._game_widget:setNumbers(state.board:getField())
    self:_updateInfo()
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
    if state:move(dir) then
        local board = state.board
        local new_tile_pos = board:placeNew()
        self._game_widget:setNumbers(board:getField(), new_tile_pos)
        state:pushToHistory()
        self:_updateInfo()
        -- Update undo, redo buttons
        UIManager:setDirty(self, "ui", self._buttons.dimen)
    end
    return true
end

function Game2048Screen:_updateInfo()
    local info = self.state.info
    local ui = self._info_board
    ui.score:setValue(tostring(info.score))
    ui.best:setValue(tostring(info.best))
    ui.moves:setValue(tostring(info.moves))
    ui.retries:setValue(tostring(info.retries))
    ui.timer:setValue(timerToString(info:calculateCurrentTimer()))
end

function Game2048Screen:onUndo()
    local state = self.state
    state:historyUndo()
    self._game_widget:setNumbers(state.board:getField())
    self:_updateInfo()
    UIManager:setDirty(self, "ui", self._buttons.dimen)
    return true
end

function Game2048Screen:onRedo()
    local state = self.state
    state:historyRedo()
    self._game_widget:setNumbers(state.board:getField())
    self:_updateInfo()
    UIManager:setDirty(self, "ui", self._buttons.dimen)
    return true
end

function Game2048Screen:onSuspend()
    self.state.info:stop()
end

function Game2048Screen:onResume()
    self.state.info:start()
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
    self.state.info:stop()
    self.storage:saveState(self.state)
    self.storage:flush()
end

return Game2048