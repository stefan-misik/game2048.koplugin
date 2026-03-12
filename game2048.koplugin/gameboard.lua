
---@alias Direction "up"|"down"|"left"|"right"

---@class GameBoard
local GameBoard = {
    -- Array containing the field
    field = nil,
    -- internally used
    _size = 4,
}
GameBoard.__index = GameBoard

-- 10% chance of getting 4 tile
local NEW_4_TILE_CHANCE_NUM = 1
local NEW_4_TILE_CHANCE_DEN = 10

local ALLOWED_LENGTHS = {
    [4] = 2, [9] = 3, [16] = 4, [25] = 5,
}

function GameBoard:new(obj)
    obj = obj or {
        field = nil,
        _size = 4,
    }
    setmetatable(obj, self)

    -- Ensure invariants
    if obj.field then
        local size = math.floor(math.sqrt(#obj.field))
        if (size * size) == #obj.field then
            obj._size = size
        else
            obj:reset()
        end
    end
    return obj
end

function GameBoard:reset()
    -- Use the current value
    self:setSize(self._size)
end

function GameBoard:copy()
    return GameBoard:new{
        field = self.field and {unpack(self.field)} or nil,
        _size = self._size,
    }
end

function GameBoard:setSize(size)
    self._size = size
    local field = {}
    for n = 1, (size * size) do
        field[n] = 0
    end
    self.field = field
end

function GameBoard:getSize()
    return self._size
end

function GameBoard:getField()
    return self.field
end

function GameBoard:getFieldCopy()
    return { unpack(self.field) }
end

function GameBoard:setFieldCopy(field)
    local new_size = ALLOWED_LENGTHS[#field]
    if not new_size then
        return false
    end
    self.field = { unpack(field) }
    self._size = new_size
    return true
end

--- Get an element
---@param x integer Column
---@param y integer Row
---@return integer
function GameBoard:getElement(x, y)
    return self.field[x + (self._size * (y - 1))]
end

--- Shift the game board in given direction
---@param dir Direction Direction to shift the game board in
---@param new_tile_cb ?function callback, when two tile merge and value of new tile is passed
---@return boolean success Performed some shift
function GameBoard:shift(dir, new_tile_cb)
    local size = self._size
    -- This are variables that are used to navigate across game field depending on the chosen direction on movement
    local pos, tile_dist, group_dist
    if dir == "up" then
        pos, tile_dist, group_dist = 1, size, 1
    elseif dir == "down" then
        pos, tile_dist, group_dist = ((size * (size - 1)) + 1), -size, 1
    elseif dir == "left" then
        pos, tile_dist, group_dist = 1, 1, size
    elseif dir == "right" then
        pos, tile_dist, group_dist = size, -1, size
    else
        return false -- nothing to do
    end

    new_tile_cb = new_tile_cb or function(_) end
    -- perform the movement
    local field = self.field
    if not field then
        return false
    end
    local did_shift = false
    for group = 1, size do
        do  -- First pass: combine tiles
            local tail_pos, head_pos = pos, pos + tile_dist
            for pair = 1, (size - 1) do
                local head_value = field[head_pos]

                if 0 ~= head_value then
                    if head_value == field[tail_pos] then
                        -- Deposit the new value at tail position, since if we put it into head
                        -- position, it would be considered the second time (as a tail), which
                        -- will lead to a tile being combined multiple times
                        local new_value = head_value + 1
                        new_tile_cb(new_value)
                        field[tail_pos] = new_value
                        field[head_pos] = 0 -- mark as empty
                        did_shift = true
                    end
                    tail_pos = head_pos  -- retract the tail if head is not empty
                end

                head_pos = head_pos + tile_dist
            end
        end
        do  -- Second pass: shift tiles
            local deposit_pos, pick_pos = pos, pos + tile_dist
            for pair = 1, (size - 1) do
                local pick_value = field[pick_pos]

                if 0 == field[deposit_pos] then
                    if 0 ~= pick_value then
                        field[deposit_pos] = pick_value
                        field[pick_pos] = 0  -- mark as empty
                        deposit_pos = deposit_pos + tile_dist
                        did_shift = true
                    end
                else
                    deposit_pos = deposit_pos + tile_dist
                end

                pick_pos = pick_pos + tile_dist
            end
        end
        -- Move to the next group
        pos = pos + group_dist
    end
    return did_shift
end

---Place a new tile in the field
---@return integer|nil location
function GameBoard:placeNew()
    local field = self.field
    if not field then
        return nil
    end

    -- First count the empty spots
    local empty_spots = 0
    for n = 1, #field do
        if 0 == field[n] then
            empty_spots = empty_spots + 1
        end
    end
    if 0 == empty_spots then
        -- Nowhere to place the new tile
        return nil
    end

    -- Place the new tile
    local new_value = (math.random(NEW_4_TILE_CHANCE_DEN) <= NEW_4_TILE_CHANCE_NUM) and 2 or 1
    local place_dist = math.random(empty_spots)
    local place_pos = nil
    for n = 1, #field do
        if 0 == field[n] then
            if 1 == place_dist then
                -- Place the new value here and terminate the iteration
                field[n] = new_value
                place_pos = n
                break
            end
            place_dist = place_dist - 1
        end
    end
    return place_pos
end

function GameBoard:dump()
    local size = self._size
    local text = ""
    for row = 1, size do
        for col = 1, size do
            text = text .. string.format(" % 2i ", self:getElement(col, row))
        end
        if row < size then
            text = text .. "\n"
        end
    end
    return text
end

return GameBoard
