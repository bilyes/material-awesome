local awful = require("awful")
local watch = require("awful.widget.watch")
local wibox = require("wibox")
local dpi = require('beautiful').xresources.apply_dpi

local ramgraph_widget = {}

local args = args or {}
local timeout = args.timeout or 1

ramgraph_widget = wibox.widget {
    border_width = 0,
    max_value = 1,
    value = 0.5,
    paddings = 1,
    forced_width = dpi(30),
    forced_height = dpi(24),
    color = "#339933",
    background_color = "#264d00",
    widget = wibox.widget.progressbar
}

--local ram_popup =
  --awful.tooltip(
  --{
    --objects = {ramgraph_widget},
    --mode = 'outside',
    --align = 'left',
    --preferred_positions = {'right', 'left', 'top', 'bottom'}
  --}
--)

local function getPercentage(value, total)
    return math.floor(value / total * 100 + 0.5) .. '%'
end

local usage = wibox.widget {
    text = "",
    align = 'center',
    valign = 'center',
    opacity = 0.5,
    font = 'Roboto Mono 8',
    widget = wibox.widget.textbox
}

watch('bash -c "LANGUAGE=en_US.UTF-8 free | grep -z Mem.*Swap.*"', timeout,
    function(widget, stdout, stderr, exitreason, exitcode)
        local total, used, free, shared, buff_cache, available, total_swap, used_swap, free_swap =
            stdout:match('(%d+)%s*(%d+)%s*(%d+)%s*(%d+)%s*(%d+)%s*(%d+)%s*Swap:%s*(%d+)%s*(%d+)%s*(%d+)')

        --percentage_value = getPercentage(used, total)
        widget.value = used / total
        usage.text = getPercentage(used, total)
        --ram_popup.text = usage.text
    end,
    ramgraph_widget
)

return wibox.widget {
    wibox.container.rotate(ramgraph_widget, 'east'),
    usage,
    layout = wibox.layout.stack
}
