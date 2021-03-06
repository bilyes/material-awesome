local beautiful = require('beautiful')
local filesystem = require('gears.filesystem')
local wibox = require('wibox')
local watch = require('awful.widget.watch')

local font_name = beautiful.font:gsub("%s%d+$", "")
--local font_name = config.font_name or beautiful.font:gsub("%s%d+$", "")

local temperature_widget = wibox.widget {
    text = "",
    align = 'center',
    font = font_name .. ' 10',
    widget = wibox.widget.textbox
}

watch(
  'bash -c "cat /sys/class/thermal/thermal_zone0/temp"',
  5,
  function(widget, stdout)
    local temp = stdout:match('(%d+)')
    widget.text = math.floor(temp / 1000 + 0.5)
    collectgarbage('collect')
  end,
  temperature_widget
)

return wibox.widget {
    {
        resize = true,
        widget = wibox.widget.imagebox,
        image = filesystem.get_configuration_dir() .. 'widget/temperature/icons/thermometer.png'
    },
    temperature_widget,
    layout = wibox.layout.fixed.horizontal
}
