local BD = require("ui/bidi")
local Blitbuffer = require("ffi/blitbuffer")
local Device = require("device")
local Font = require("ui/font")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local InputContainer = require("ui/widget/container/inputcontainer")
local RenderText = require("ui/rendertext")
local Size = require("ui/size")
local UIManager = require("ui/uimanager")

local Screen = Device.screen

local ALLOWED_LENGTHS = {
    [9] = 3, [16] = 4, [25] = 5,
}

local MAX_VALUE = 2 + 25
-- Calculate the strings to show in tiles
local VALUE_STR = {}
for n = 1,MAX_VALUE do
    VALUE_STR[n] = tostring(math.pow(2, n))
end

-- Configuration
local BORDER_SIZE_FOCUS = Size.line.thin
local BORDER_SIZE = Size.line.thick
local BORDER_COLOR = Blitbuffer.COLOR_BLACK
local FRAME_COLOR = Blitbuffer.COLOR_WHITE
local FRAME_RADIUS = Screen:scaleBySize(15)
local TILE_RADIUS = Screen:scaleBySize(10)
local TILE_COLOR = Blitbuffer.COLOR_WHITE
local TILE_BORDER_SIZE = Size.line.medium
local TILE_BORDER_COLOR = Blitbuffer.COLOR_BLACK
local TILE_KERNING = true
local TILE_FALLBACK_TEXT = "∞"
local INNER_TILE_MARGIN = Screen:scaleBySize(5)
local INNER_TILE_PADDING = Screen:scaleBySize(5)
local INNER_TILE_DEFAULT_COLOR = Blitbuffer.COLOR_GRAY_D
local PADDING = Screen:scaleBySize(10)
local SPACING = Screen:scaleBySize(10)


local Game2048Widget = InputContainer:extend{
    -- Array of numbers to show, it has to be square (N*N) elements long
    numbers = nil,
    -- Width of the container, height is identical
    width = nil,
    -- Font options, the specified face size will be the maximum size, text may
    -- be shrunk in order to fit te tiles
    face = nil,
    bold = false,

    -- Tile color palette
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

    -- Notify about events
    move_handler = nil,

    -- for internal use
    _size = nil,
    _tile_side = nil,
    _value_str_props = nil,
    _has_focus = false,
    _is_active = false,
}

function Game2048Widget:init()
    self.width = self.width or (Screen:getWidth() * 0.9)
    -- Is always square
    self.dimen = Geom:new{w = self.width, h = self.width}

    -- Ensure an valid numbers are used
    if not self.numbers then
        local numbers = {}
        for n = 1, 16 do
            numbers[#numbers+1] = 0
        end
        self.numbers = numbers
    end

    if not self.face then
        self.face = Font:getFace("tfont", 35)
    end
    -- Adjust bold face (source: textwidget.lua)
    self.face, self.bold = Font:getAdjustedFace(self.face, self.bold)

    -- Register events
    self:_registerKeyEvents()
    self:_registerTouchEvents()

    -- Perform first update
    self:_update()
end


function Game2048Widget:paintTo(bb, x, y)
    if not self.dimen then
        self.dimen = Geom:new{
            x = x, y = y,
            w = self.width,
            h = self.width  -- Widget is always square
        }
    else
        self.dimen.x = x
        self.dimen.y = y
    end
    bb:paintRoundedRect(x, y, self.width, self.width, FRAME_COLOR, FRAME_RADIUS)
    if self._is_active then
        bb:paintBorder(x, y, self.width, self.width, BORDER_SIZE, BORDER_COLOR, FRAME_RADIUS)
    elseif self._has_focus then
        bb:paintBorder(x, y, self.width, self.width, BORDER_SIZE_FOCUS, BORDER_COLOR, FRAME_RADIUS)
    end

    -- Continue only if a valid 
    local size = self._size
    if not size then
        return  -- When size is nil the numbers are invalid
    end

    -- Paint the tiles
    local tile_side = self._tile_side
    local tile_dist = tile_side + SPACING
    local tile_y = y + PADDING
    local number_pos = 1
    for row = 1,size do
        local tile_x = x + PADDING
        for col = 1,size do
            bb:paintRoundedRect(tile_x, tile_y, tile_side, tile_side,
                    TILE_COLOR, TILE_RADIUS)
            bb:paintBorder(tile_x, tile_y, tile_side, tile_side,
                    TILE_BORDER_SIZE, TILE_BORDER_COLOR, TILE_RADIUS)
            
            -- No need to check the boundaries as we would not be here if #self.numbers ~= (size * size)
            local value = self.numbers[number_pos]
            if value > 0 then
                local value_str, prop = VALUE_STR[value] or TILE_FALLBACK_TEXT,
                    self._value_str_props[value] or self._value_str_props[MAX_VALUE + 1]  -- ... or fallback
                local bg_color, fg_color = self:_getTileColors(value)
                bb:paintRoundedRect(tile_x + INNER_TILE_MARGIN, tile_y + INNER_TILE_MARGIN,
                    tile_side - (2 * INNER_TILE_MARGIN), tile_side - (2 * INNER_TILE_MARGIN),
                    bg_color, TILE_RADIUS - INNER_TILE_MARGIN)
                RenderText:renderUtf8Text(bb,
                    tile_x + math.floor((tile_side - prop.size.w) / 2),
                    tile_y + math.floor((tile_side + prop.size.h) / 2),
                    prop.face, value_str, TILE_KERNING, self.bold, fg_color)
            end
            tile_x = tile_x + tile_dist
            number_pos = number_pos + 1
        end
        tile_y = tile_y + tile_dist
    end

end

function Game2048Widget:setNumbers(numbers)
    if ALLOWED_LENGTHS[#numbers] then
        self.numbers = numbers
        self:_update()
        UIManager:setDirty(self.show_parent or self, "ui", self.dimen)
    end
end


function Game2048Widget:_update()
    local size = ALLOWED_LENGTHS[#self.numbers] or nil
    if size == self._size then
        return -- Size of the game board has not changed
    end
    self._size = size
    if not size then
        return  -- nothing to do
    end

    -- tile width
    local inner_width = self.width - (2 * PADDING)
    local all_gaps = SPACING * (self._size - 1)
    self._tile_side = math.floor((inner_width - all_gaps) / self._size)

    -- Value string properties
    local max_text_width = self._tile_side - (2 * (INNER_TILE_MARGIN + INNER_TILE_PADDING))
    local value_str_props = {}
    for n = 1, (MAX_VALUE + 1) do  -- One additional props for the fallback text
        local value_str = VALUE_STR[n] or TILE_FALLBACK_TEXT
        local face = self.face
        local tsize = nil
        while true do
            tsize = RenderText:sizeUtf8Text(0, Screen:getWidth(), face, value_str, TILE_KERNING, self.bold)
            if tsize.x <= max_text_width then
                break
            end
            face = Font:getFace(face.orig_font, face.orig_size - 1)
        end
        value_str_props[n] = { face = face, size = {w = tsize.x, h = tsize.y_top} }
    end
    self._value_str_props = value_str_props
end

function Game2048Widget:_getTileColors(value)
    -- Saturate at last tile color
    local bg_color = self.palette[math.min(#self.palette, value)] or INNER_TILE_DEFAULT_COLOR
    local is_dark = bg_color:getColor8().a <= 0x44
    return bg_color, is_dark and Blitbuffer.COLOR_WHITE or Blitbuffer.COLOR_BLACK
end

function Game2048Widget:_registerKeyEvents()
    if Device:hasDPad() then
        self.key_events.UpMove = { { "Up" }, event = "Game2048Move", args = "up" }
        self.key_events.DownMove = { { "Down" }, event = "Game2048Move", args = "down" }
        self.key_events.LeftMove = { { "Left" }, event = "Game2048Move", args = "left" }
        self.key_events.RightMove = { { "Right" }, event = "Game2048Move", args = "right" }
        --self.key_events.Press = { { "Press" } }
    end
end

function Game2048Widget:_registerTouchEvents()
    if Device:isTouchDevice() then
        self.ges_events.Swipe = { GestureRange:new{ ges = "swipe", range = self.dimen, }}
    end
    -- Tap gesture is passed by FucusManager
    self.ges_events.TapGame2048 = { GestureRange:new{ ges = "tap", range = self.dimen, }}
end

function Game2048Widget:setActive(active)
    self._is_active = active
    UIManager:setDirty(self.show_parent or self, "fast", self:getSize())
end

Game2048Widget.onPhysicalKeyboardConnected = Game2048Widget._registerKeyEvents

function Game2048Widget:onGame2048Move(dir)
    if not self._is_active then
        return false
    end
    if self.move_handler then
        self.move_handler(dir)
    end
    return true
end

function Game2048Widget:onTapGame2048()
    if self._has_focus then
        self._is_active = not self._is_active
        UIManager:setDirty(self.show_parent or self, "fast", self:getSize())
    end
    return false
end

local GES_TO_DIR_MAP = {
    ["west"] = "left", ["east"] = "right", ["south"] = "down", ["north"] = "up"
}

function Game2048Widget:onSwipe(arg, ges_ev)
    local dir = GES_TO_DIR_MAP[ges_ev.direction]
    if dir then
        if self.move_handler then
            self.move_handler(dir)
        end
        return true
    end
    return false
end

function Game2048Widget:onFocus()
    self._has_focus = true
end

function Game2048Widget:onUnfocus()
    self._has_focus = false
    self._is_active = false
end


return Game2048Widget