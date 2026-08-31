local ButtonDialog = require("ui/widget/buttondialog")
local ConfigDialog = require("ui/widget/configdialog")
local Event = require("ui/event")
local InfoMessage = require("ui/widget/infomessage")  -- luacheck:ignore
local InputDialog = require("ui/widget/inputdialog")
local InputContainer = require("ui/widget/container/inputcontainer")
local UIManager = require("ui/uimanager")
local _ = require("gettext")


local Game2048Settings = {
    ui = nil,
}
Game2048Settings.__index = Game2048Settings

Game2048Settings.DEFAULTS = {
    profile = "default",
    size = 4,
    new_tile_delay = 0.1,
    theme = "default",
    tile_value_style = "plain",
}

Game2048Settings.PROFILES = {
    { id = "default",  fallback_name = "1" },
    { id = "player2",  fallback_name = "2" },
    { id = "player3",  fallback_name = "3" },
    { id = "player4",  fallback_name = "4" },
    { id = "player5",  fallback_name = "5" },
    { id = "player6",  fallback_name = "6" },
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

--- Get the display name for a profile
---@param profile_id string Internal profile identifier
---@param profile_names ?table Optional mapping of profile_id -> custom name
---@return string display_name
function Game2048Settings.getProfileDisplayName(profile_id, profile_names)
    if profile_names then
        local custom = profile_names[profile_id]
        if custom and custom ~= "" then
            return custom
        end
    end
    for _, p in ipairs(Game2048Settings.PROFILES) do
        if p.id == profile_id then
            return p.fallback_name
        end
    end
    return profile_id
end

--- Get toggle labels for all profiles
---@param profile_names ?table Optional mapping of profile_id -> custom name
---@return table toggle_labels
function Game2048Settings.getProfileToggleLabels(profile_names)
    local labels = {}
    for _, p in ipairs(Game2048Settings.PROFILES) do
        table.insert(labels, Game2048Settings.getProfileDisplayName(p.id, profile_names))
    end
    return labels
end


local Game2048Config = InputContainer:extend{
    new_settings_callback = nil,
    rename_profile_callback = nil,
    profile_names_provider = nil,
    last_panel_index = 1,
}

function Game2048Config.makeDefaultSettings()
    return Game2048Settings:new()
end

Game2048Config.PROFILES = Game2048Settings.PROFILES
Game2048Config.getProfileDisplayName = Game2048Settings.getProfileDisplayName
Game2048Config.getProfileToggleLabels = Game2048Settings.getProfileToggleLabels

function Game2048Config:init()
    local profile_values = {}
    for _, p in ipairs(Game2048Settings.PROFILES) do
        table.insert(profile_values, p.id)
    end

    local profile_names = self.profile_names_provider and self.profile_names_provider() or nil

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
                {
                    name = "profile",
                    name_text = _("Profile"),
                    toggle = Game2048Settings.getProfileToggleLabels(profile_names),
                    values = profile_values,
                    default_value = Game2048Settings.DEFAULTS.profile,
                    event = "DummyEvent",
                    args = profile_values,
                },
                {
                    name = "rename_profile",
                    name_text = _("Rename Profile"),
                    item_text = { _("Rename") .. "…" },
                    event = "RenameProfile",
                },
                {
                    name = "tile_value_style",
                    name_text = _("Tile Values"),
                    toggle = { _("Number"), _("k suffix") },
                    values = { "plain", "compact" },
                    default_value = Game2048Settings.DEFAULTS.tile_value_style,
                    event = "DummyEvent",
                    args = { "plain", "compact" },
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

function Game2048Config:onRenameProfile()
    local settings = self.configurable
    local current_profile = settings.profile
    local profile_names = self.profile_names_provider and self.profile_names_provider() or nil
    local current_name = Game2048Settings.getProfileDisplayName(current_profile, profile_names)

    self._rename_dialog = InputDialog:new{
        title = _("Rename Profile"),
        input = current_name,
        input_hint = current_name,
        buttons = {{
            {
                text = _("Cancel"),
                id = "close",
                callback = function()
                    UIManager:close(self._rename_dialog)
                    self._rename_dialog = nil
                end,
            },
            {
                text = _("Clear"),
                callback = function()
                    UIManager:close(self._rename_dialog)
                    self._rename_dialog = nil
                    if self.rename_profile_callback then
                        self.rename_profile_callback(current_profile, nil)
                    end
                    self:_refreshProfileToggleLabels()
                end,
            },
            {
                text = _("Rename"),
                is_enter_default = true,
                callback = function()
                    local new_name = self._rename_dialog:getInputText()
                    if new_name == "" then
                        new_name = nil
                    end
                    UIManager:close(self._rename_dialog)
                    self._rename_dialog = nil
                    if self.rename_profile_callback then
                        self.rename_profile_callback(current_profile, new_name)
                    end
                    self:_refreshProfileToggleLabels()
                end,
            },
        }},
    }

    UIManager:show(self._rename_dialog)
    self._rename_dialog:onShowKeyboard()
end

function Game2048Config:_refreshProfileToggleLabels()
    local profile_names = self.profile_names_provider and self.profile_names_provider() or nil
    -- Update the toggle labels in the profile option
    local settings_panel = self.options[2]
    if settings_panel then
        for _, opt in ipairs(settings_panel.options) do
            if opt.name == "profile" then
                opt.toggle = Game2048Settings.getProfileToggleLabels(profile_names)
                break
            end
        end
    end
    -- Re-init the config dialog to reflect changes
    if self.config_dialog then
        self.config_dialog:init()
        UIManager:setDirty(self.config_dialog, "ui")
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

    -- Report selected events to parent
    if "theme" == option_name then
        self.ui:handleEvent(Event:new("ThemeChange", option_value))
    elseif "profile" == option_name then
        self.ui:handleEvent(Event:new("ProfileChange", option_value))
    elseif "tile_value_style" == option_name then
        self.ui:handleEvent(Event:new("TileValueStyleChange", option_value))
    end

    return true
end

return Game2048Config
