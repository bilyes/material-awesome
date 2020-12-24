-------------------------------------------------
-- Wifi Widget for Awesome Window Manager
-- Shows the Wifi signal strength using the WI tool

-- @author Ilyess Bachiri
-- @copyright 2021-present Ilyess Bachiri
-------------------------------------------------

local awful = require('awful')
local clickable_container = require('widget.material.clickable-container')
local dpi = require('beautiful').xresources.apply_dpi
local filesystem = require('gears.filesystem')
local gears = require('gears')
local watch = require('awful.widget.watch')
local wibox = require('wibox')

local PATH_TO_ICONS = filesystem.get_configuration_dir() .. '/widget/wifi/icons/'
local interface = 'wlp5s0'
local connected = false
local essid = 'N/A'

local widget =
  wibox.widget {
  {
    id = 'icon',
    widget = wibox.widget.imagebox,
    resize = true
  },
  layout = wibox.layout.align.horizontal
}

--local widget_button = clickable_container(wibox.container.margin(widget, dpi(14), dpi(14), dpi(4), dpi(4)))
local widget_button = clickable_container(wibox.container.margin(widget, dpi(9), dpi(9), dpi(4), dpi(4)))
widget_button:buttons(
  gears.table.join(
    awful.button(
      {},
      1,
      nil,
      function()
        awful.spawn('wicd-client -n')
      end
    )
  )
)
-- Alternative to naughty.notify - tooltip. You can compare both and choose the preferred one
awful.tooltip(
  {
    objects = {widget_button},
    mode = 'outside',
    align = 'right',
    timer_function = function()
      if connected then
        return 'Connected to ' .. essid
      else
        return 'Wireless network is disconnected'
      end
    end,
    preferred_positions = {'right', 'left', 'top', 'bottom'},
    margin_leftright = dpi(8),
    margin_topbottom = dpi(8)
  }
)

local function grabText()
  if connected then
    awful.spawn.easy_async(
      'iw dev ' .. interface .. ' link',
      function(stdout)
        essid = stdout:match('SSID:(.-)\n')
        if (essid == nil) then
          essid = 'N/A'
        end
      end
    )
  end
end

local function get_icon_name(wifi_strength)
  local iconName = 'wifi-strength'

  if (wifi_strength == nil) then
      return iconName .. '-off'
  end

  return iconName .. '-' .. math.floor(wifi_strength / 25 + 0.5)
end

local update_widget = function(_, stdout)
  local wifi_strength = tonumber(stdout)

  widget.icon:set_image(PATH_TO_ICONS .. get_icon_name(wifi_strength) .. '.svg')

  if ((wifi_strength ~= nil) and (essid == 'N/A' or essid == nil)) then
    grabText()
  end
  collectgarbage('collect')
end

watch(
  "awk 'NR==3 {printf \"%3.0f\" ,($3/70)*100}' /proc/net/wireless",
  5,
  update_widget,
  widget
)

widget:connect_signal(
  'mouse::enter',
  function()
    grabText()
  end
)

return widget_button
