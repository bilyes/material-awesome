local wibox = require('wibox')
local gears = require('gears')
local clickable_container = require('widget.material.clickable-container')
local dpi = require('beautiful').xresources.apply_dpi

function build(imagebox, args)
  local margin = dpi(7)

  -- return wibox.container.margin(container, 7, 7, 7, 7)
  return wibox.widget {
    wibox.widget {
      wibox.widget {
        imagebox,
        top = margin,
        left = margin,
        right = margin,
        bottom = margin,
        widget = wibox.container.margin
      },
      shape = gears.shape.circle,
      widget = clickable_container
    },
    top = margin,
    left = margin,
    right = margin,
    bottom = margin,
    widget = wibox.container.margin
  }
end

return build
