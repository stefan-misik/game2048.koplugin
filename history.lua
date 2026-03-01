---@class History
local History = {
    capacity = 10,

    _history = nil,
    _head = 1,
    _tail = 1,
    _position = nil,
}

local function prevPosition(pos, capacity)
    return 1 ~= pos and pos - 1 or capacity
end

local function nextPosition(pos, capacity)
    return capacity ~= pos and pos + 1 or 1
end

function History:new(obj)
    obj = obj or {
        capacity = 10,

        _history = nil,
        _head = 1,
        _tail = 1,
        _position = nil,
    }
    setmetatable(obj, self)
    self.__index = self
    -- Ensure invariants
    if not obj._history then
        obj._history = {}
    end
    if not obj._position then
        -- Position needs to be one item behind head in case there is nothing to redo
        obj._position = prevPosition(obj._head, obj.capacity)
    end
    return obj
end

function History:clear()
    self._history = {}
    self._head = 1
    self._tail = 1
    self._position = prevPosition(self._head, self.capacity)
end

function History:push(item)
    -- new position should discard any items that may be between current position and head, i.e. undo-ed items,
    -- therefore we are placing new history item after current position, not at head. 
    local new_position = nextPosition(self._position, self.capacity)
    -- free space taken by discarded undo-ed items
    self:_free(new_position, self._head)
    -- Place new history item
    self._history[new_position] = item

    -- Update history pointers
    local new_head = nextPosition(new_position, self.capacity)
    if new_head == self._tail then
        -- Forget old history items
        self._tail = nextPosition(new_head, self.capacity)
    end
    self._head = new_head
    self._position = new_position
end

function History:isEmpty()
    return self._head == self._tail
end

function History:current()
    if self:isEmpty() then
        return nil
    end
    return self._history[self._position]
end

function History:canUndo()
    return not self:isEmpty() and self._position ~= self._tail
end

function History:canRedo()
    return nextPosition(self._position, self.capacity) ~= self._head
end

function History:undo()
    if not self:canUndo() then
        return nil
    end
    self._position = prevPosition(self._position, self.capacity)
    return self._history[self._position]
end

function History:redo()
    if not self:canRedo() then
        return nil
    end
    self._position = nextPosition(self._position, self.capacity)
    return self._history[self._position]
end

function History:_free(from, to)
    local pos = from
    local history = self._history
    local capacity = self.capacity
    while pos ~= to do
        -- place something in the history buffer to prevent the field from being removed completely
        history[pos] = -1
        pos = nextPosition(pos, capacity)
    end
end

return History