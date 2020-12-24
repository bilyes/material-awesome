-------------------------------------------------
-- Battery Widget for Awesome Window Manager
-- Shows the battery status using the ACPI tool

-- @author Ilyess Bachiri
-- @copyright 2021-present Ilyess Bachiri
-------------------------------------------------

local awful = require('awful')
local clickable_container = require('widget.material.clickable-container')
local dpi = require('beautiful').xresources.apply_dpi
local filesystem = require('gears.filesystem')
local gears = require('gears')
local naughty = require('naughty')
local watch = require('awful.widget.watch')
local wibox = require('wibox')

-- acpi sample outputs
-- Battery 0: Discharging, 75%, 01:51:38 remaining
-- Battery 0: Charging, 53%, 00:57:43 until charged

local PATH_TO_ICONS = filesystem.get_configuration_dir() .. '/widget/battery/icons/'

local widget =
  wibox.widget {
  {
    id = 'icon',
    widget = wibox.widget.imagebox,
    resize = true
  },
  layout = wibox.layout.fixed.horizontal
}

--local widget_button = clickable_container(wibox.container.margin(widget, dpi(14), dpi(14), 4, 4))
local widget_button = clickable_container(wibox.container.margin(widget, dpi(9), dpi(9), dpi(4), dpi(4)))
widget_button:buttons(
  gears.table.join(
    awful.button(
      {},
      1,
      nil,
      function()
        awful.spawn('xfce4-power-manager-settings')
      end
    )
  )
)
-- Alternative to naughty.notify - tooltip. You can compare both and choose the preferred one
local battery_popup =
  awful.tooltip(
  {
    objects = {widget_button},
    mode = 'outside',
    align = 'left',
    preferred_positions = {'right', 'left', 'top', 'bottom'}
  }
)

-- To use colors from beautiful theme put
-- following lines in rc.lua before require("battery"):
--beautiful.tooltip_fg = beautiful.fg_normal
--beautiful.tooltip_bg = beautiful.bg_normal

local function show_battery_warning()
  naughty.notify {
    icon = PATH_TO_ICONS .. 'battery-alert.svg',
    icon_size = dpi(48),
    text = 'Huston, we have a problem',
    title = 'Battery is dying',
    timeout = 5,
    hover_timeout = 0.5,
    position = 'bottom_left',
    bg = '#d32f2f',
    fg = '#EEE9EF',
    width = 248
  }
end

local last_battery_check = os.time()

function get_icon_name(charge)
  local iconName = 'battery'

  if status == 'Charging' or status == 'Full' then
    iconName = iconName .. '-charging'
  end

  local roundedCharge = math.floor(charge / 10) * 10
  if (roundedCharge == 0) then
    iconName = iconName .. '-outline'
  elseif (roundedCharge ~= 100) then
    iconName = iconName .. '-' .. roundedCharge
  end

  return iconName
end

function notify_if_low(charge)
  if (charge >= 0 and charge < 15) then
    if status ~= 'Charging' and os.difftime(os.time(), last_battery_check) > 300 then
      -- if 5 minutes have elapsed since the last warning
      last_battery_check = _G.time()

      show_battery_warning()
    end
  end
end

local update_widget = function(_, stdout)

  local battery_info = {}
  local capacities = {}
  for s in stdout:gmatch('[^\r\n]+') do
    local status, charge_str, time = string.match(s, '.+: (%a+), (%d?%d?%d)%%,?.*')
    if status ~= nil then
      table.insert(battery_info, {status = status, charge = tonumber(charge_str)})
    else
      local cap_str = string.match(s, '.+:.+last full capacity (%d+)')
      table.insert(capacities, tonumber(cap_str))
    end
  end

  local capacity = 0
  for _, cap in ipairs(capacities) do
    capacity = capacity + cap
  end

  local charge = 0
  local status
  for i, batt in ipairs(battery_info) do
    if batt.charge >= charge then
      status = batt.status -- use most charged battery status
    -- this is arbitrary, and maybe another metric should be used
    end

    charge = charge + batt.charge

    if capacities[i]  ~= nil then
        charge = charge * capacities[i]
    end
  end
  charge = charge / capacity

  notify_if_low(charge)
  widget.icon:set_image(PATH_TO_ICONS .. get_icon_name(charge) .. '.svg')
  -- Update popup text
  battery_popup.text = string.gsub(stdout, '\n$', '')
  collectgarbage('collect')
end

watch(
  'acpi -i',
  1,
  update_widget,
  widget
)

return widget_button
