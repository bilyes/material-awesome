-- Ilyess Bachiri, 2021
--
-- Memory Monitor for awesome that changes color as the memory usage goes up


local awful = require("awful")
local beautiful = require("beautiful")
local filesystem = require('gears.filesystem')
local dpi = require('beautiful').xresources.apply_dpi
local watch = require("awful.widget.watch")
local wibox = require("wibox")

local font_name = beautiful.font:gsub("%s%d+$", "")
--local font_name = config.font_name or beautiful.font:gsub("%s%d+$", "")

widget = wibox.widget.textbox()

function get_color(memory_usage)
    if memory_usage > 94 then
        return "#FF0000"
    end

    if memory_usage > 85 then
        return "#FF8000"
    end

    if memory_usage > 75 then
        return "#F5F549"
    end
    --return "#669900"
    return beautiful.fg_normal
end

function update_widget(widget, stdout)
    local mem = tonumber(stdout)
    widget:set_markup("<span font='" .. font_name .. " 10' color='" .. get_color(mem) .. "'>" .. mem .. "G </span>")
end

watch(
    [[ /bin/bash -c "free | grep Mem | awk '{printf(\"%.1f\n\", $3 / 1024 / 1024)}'" ]],
    10,
    update_widget,
    widget
)

return wibox.widget {
    {
        resize = true,
        widget = wibox.widget.imagebox,
        image = filesystem.get_configuration_dir() .. '/widget/memory/icons/memory-stick.png'
    },
    widget,
    spacing = dpi(3),
    layout = wibox.layout.fixed.horizontal
}
