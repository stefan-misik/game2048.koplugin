local ButtonDialog = require("ui/widget/buttondialog")
local ConfigDialog = require("ui/widget/configdialog")
local InfoMessage = require("ui/widget/infomessage")  -- luacheck:ignore
local InputContainer = require("ui/widget/container/inputcontainer")
local UIManager = require("ui/uimanager")
local _ = require("gettext")


local Game2048Settings = { }
Game2048Settings.__index = Game2048Settings

Game2048Settings.DEFAULTS = {
    size = 4,
    new_tile_delay = 0.1,
    theme = "default",
}

function Game2048Settings:new(obj)
    obj = obj or { };
    setmetatable(obj, self)

    obj:_init()
    return obj
end

function Game2048Settings:_init()
    self:reset()
end

function Game2048Settings:reset()
    -- Copy the defaults
    for name, value in pairs(Game2048Settings.DEFAULTS) do
        self[name] = value
    end
end

function Game2048Settings:merge(obj)
    if not obj then
        return
    end
    for name, _ in pairs(Game2048Settings.DEFAULTS) do
        local new_value = obj[name]
        if new_value ~= nil then
            self[name] = new_value
        end
    end
end

function Game2048Settings:dump()
    local dump = {}
    for name, _ in pairs(Game2048Settings.DEFAULTS) do
        dump[name] = self[name]
    end
    return dump
end


local Game2048Config = InputContainer:extend{
    new_settings_callback = nil,
    last_panel_index = 1,
}

function Game2048Config.makeDefaultSettings()
    return Game2048Settings:new()
end

function Game2048Config:init()
    self.options = {
        prefix = "game2048",
        {
            icon = "zoom.content",
            options = {
                {
                    name = "size",
                    name_text = _("Size"),
                    toggle = { "2x2", "3x3", "4x4", "5x5" },
                    values = { 2, 3, 4, 5 },
                    default_value = Game2048Settings.DEFAULTS.size,
                    event = "DummyEvent",
                    args = { 2, 3, 4, 5 },
                },
            },
        },
        {
            icon = "appbar.settings",
            options = {
                {
                    name = "new_tile_delay",
                    name_text = _("New Tile Delay"),
                    toggle = { "Off", "⅒ s", "¼ s", "½ s", "¾ s", "1 s" },
                    values = { 0.0, 0.1, 0.25, 0.5, 0.75, 1.0 },
                    default_value = Game2048Settings.DEFAULTS.new_tile_delay,
                    event = "DummyEvent",
                    args = { 0.0, 0.1, 0.25, 0.5, 0.75, 1.0 },
                },
                {
                    name = "theme",
                    name_text = _("Color Theme"),
                    item_text = { _("Select") .. "…" },
                    event = "SelectTheme",
                },
            },
        },
    }

    self._did_show_size_notification = false
end

function Game2048Config:showConfigMenu()
    self.config_dialog = ConfigDialog:new{
        document = nil,  -- Just a opaque value passed to some callbacks ???
        ui = self,
        configurable = self.configurable,
        config_options = self.options,
        is_always_active = true,
        covers_footer = true,
        close_callback = function() self:onCloseCallback() end,
    }
    self.config_dialog:onShowConfigPanel(self.last_panel_index)
    self._did_show_size_notification = false
    UIManager:show(self.config_dialog)
    return true
end

function Game2048Config:onSetDimensions(dimen)
    if self.config_dialog then
        -- init basically calls update & initGesListener and nothing else, which is exactly what we want.
        self.config_dialog:init()
    end
end

function Game2048Config:onCloseCallback()
    self.last_panel_index = self.config_dialog.panel_index
    self.config_dialog = nil
    if self.new_settings_callback then
        self.new_settings_callback()
    end
end

function Game2048Config:onSelectTheme()
    local themes = require("ui.theme.game2048widgettheme")

    local function select(theme_n)
        self:onConfigChange("theme", themes[theme_n].id)
        UIManager:close(self._theme_select_dialog)
        self._theme_select_dialog = nil
    end

    local current_theme_id = self.configurable.theme
    local buttons = {}
    for n, theme in ipairs(themes) do
        local name = current_theme_id == theme.id and theme.name .. " ✓" or theme.name
        table.insert(buttons, {{
            text = name,
            callback = function() select(n) end,
            align = "left",
        }})
    end

    self._theme_select_dialog = ButtonDialog:new{
        title = _("Select Theme"),
        buttons = buttons,
        title_align = "center",
        tap_close_callback = function()
            self._theme_select_dialog = nil
        end
    }

    UIManager:show(self._theme_select_dialog)
end

function Game2048Config:onConfigChange(option_name, option_value)
    if not self._did_show_size_notification and "size" == option_name then
        self._did_show_size_notification = true
        UIManager:show(InfoMessage:new{
            timeout = 10,
            text = _("Start a new game to change the size of the board");
        })
    end
    self.configurable[option_name] = option_value
    return true
end

return Game2048Config

