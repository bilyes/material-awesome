local wibox = require('wibox')
local mat_list_item = require('widget.material.list-item')
local mat_slider = require('widget.material.slider')
local mat_icon = require('widget.material.icon')
local icons = require('theme.icons')
local watch = require('awful.widget.watch')
local dpi = require('beautiful').xresources.apply_dpi

local temperature_widget = wibox.widget {
    text = "",
    align = 'center',
    valign = 'center',
    font = 'Roboto Mono 8',
    widget = wibox.widget.textbox
}

watch(
  'bash -c "cat /sys/class/thermal/thermal_zone0/temp"',
  2,
  function(widget, stdout)
    local temp = stdout:match('(%d+)')
    widget.text = math.floor(temp / 1000 + 0.5) .. '°C'
    collectgarbage('collect')
  end,
  temperature_widget
)

--local temperature_meter =
  --wibox.widget {
  --wibox.widget {
    --icon = icons.thermometer,
    --size = dpi(20),
    ----size = dpi(24),
    --widget = mat_icon
  --},
  --tempareture_widget,
  --widget = mat_list_item
--}

return temperature_widget
