-- Ilyess Bachiri, 2020
--
-- Memory Monitor for awesome that changes color as the memory usage goes up


local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = require('beautiful').xresources.apply_dpi

local root = os.getenv("HOME") .. "/.config/awesome/widget/memory/"

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

function testmem()
    local fd = io.popen(root .. "mem.sh simple")
    if fd then
        -- occasionally awesome craps out for no reason running the operation
        -- and fd is nil, do nothing in that case (aside from ignoring the value
        -- rather than throwing an error), it will fix itself next run
        local memstr = fd:read("*all")
        local mem = tonumber(memstr)
        fd:close()

        if widget.zenstate ~= nil then
            if widget.zenstate(mem) then
                return ""
            end
        end

        return "<span font='" .. font_name .. " 10' color='" .. get_color(mem) .. "'>" .. mem .. "G </span>"
    end
    return "N/A" -- something failed
end

widget:set_markup(testmem())

-- update every 30 secs
memtimer = timer({ timeout = 30 })
memtimer:connect_signal("timeout", function()
    widget:set_markup(testmem())
end)
memtimer:start()

return wibox.widget {
    {
        resize = true,
        widget = wibox.widget.imagebox,
        image = root .. '/icons/memory-stick.png'
    },
    widget,
    spacing = dpi(3),
    layout = wibox.layout.fixed.horizontal
}
