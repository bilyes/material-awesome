-------------------------------------------------
-- Weather Widget based on the OpenWeatherMap
-- https://openweathermap.org/
--
-- @author Ilyess Bachiri
-- @copyright 2021 Ilyess Bachiri
-------------------------------------------------
local awful = require("awful")
local beautiful = require("beautiful")
local dpi = require('beautiful').xresources.apply_dpi
local filesystem = require('gears.filesystem')
local gears = require("gears")
local json = require("json")
local naughty = require("naughty")
local watch = require("awful.widget.watch")
local wibox = require("wibox")

local config = require('widget.weather.config')

local widget_dir = filesystem.get_configuration_dir() .. '/widget/weather'

local get_forecast_cmd = [[bash -c "curl -s --show-error -X GET '%s'"]]

local function show_warning(message)
    naughty.notify {
        preset = naughty.config.presets.critical,
        title = 'Weather Widget',
        text = message
    }
end

local weather_widget = {}
local warning_shown = false
local tooltip = awful.tooltip {
    mode = 'outside',
    preferred_positions = {'bottom'}
}

local popup_width = dpi(280)

local weather_popup = awful.popup {
    ontop = true,
    visible = false,
    shape = gears.shape.rounded_rect,
    border_width = 1,
    border_color = beautiful.bg_focus,
    maximum_width = popup_width,
    offset = {y = 5},
    widget = {}
}

local icon_map = require('widget.weather.icon-map')

--- Return wind direction as a string
local function to_direction(degrees)
    -- Ref: https://www.campbellsci.eu/blog/convert-wind-directions
    if degrees == nil then return "Unknown dir" end
    local directions = {
        "N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW",
        "WSW", "W", "WNW", "NW", "NNW", "N"
    }
    return directions[math.floor((degrees % 360) / 22.5) + 1]
end

--- Convert degrees Celsius to Fahrenheit
local function celsius_to_fahrenheit(c) return c * 9 / 5 + 32 end

-- Convert degrees Fahrenheit to Celsius
local function fahrenheit_to_celsius(f) return (f - 32) * 5 / 9 end

local function gen_temperature_str(temp, fmt_str, show_other_units, units)
    local temp_str = string.format(fmt_str, temp)
    local s = temp_str .. '°' .. (units == 'metric' and 'C' or 'F')

    if (show_other_units) then
        local temp_conv, units_conv
        if (units == 'metric') then
            temp_conv = celsius_to_fahrenheit(temp)
            units_conv = 'F'
        else
            temp_conv = fahrenheit_to_celsius(temp)
            units_conv = 'C'
        end

        local temp_conv_str = string.format(fmt_str, temp_conv)
        s = s .. ' ' .. '(' .. temp_conv_str .. '°' .. units_conv .. ')'
    end
    return s
end

local function uvi_index_color(uvi)
    local color
    if uvi >= 0 and uvi < 3 then color = '#A3BE8C'
    elseif uvi >= 3 and uvi < 6 then color = '#EBCB8B'
    elseif uvi >= 6 and uvi < 8 then color = '#D08770'
    elseif uvi >= 8 and uvi < 11 then color = '#BF616A'
    elseif uvi >= 11 then color = '#B48EAD'
    end

    return '<span weight="bold" foreground="' .. color .. '">' .. uvi .. '</span>'
end

--- Validate required parameters
if config.coordinates == nil or config.api_key == nil then
    show_warning('Required parameters are not set: ' ..
                     (config.coordinates == nil and '<b>coordinates</b>' or '') ..
                     (config.api_key == nil and ', <b>api_key</b> ' or ''))
    return
end

local coordinates = config.coordinates
local api_key = config.api_key
local font_name = config.font_name or beautiful.font:gsub("%s%d+$", "")
local units = config.units or 'metric'
local time_format_12h = config.time_format_12h
local both_units_widget = config.both_units_widget or false
local show_hourly_forecast = config.show_hourly_forecast
local show_daily_forecast = config.show_daily_forecast
local icon_pack_name = config.icons or 'weather-underground-icons'
local icons_extension = config.icons_extension or '.png'
local timeout = config.timeout or 120

local icons_dir = widget_dir .. '/icons/' .. icon_pack_name .. '/'
local owm_one_cal_api =
    ('https://api.openweathermap.org/data/2.5/onecall' ..
        '?lat=' .. coordinates[1] .. '&lon=' .. coordinates[2] .. '&appid=' .. api_key ..
        '&units=' .. units .. '&exclude=minutely' ..
        (show_hourly_forecast == false and ',hourly' or '') ..
        (show_daily_forecast == false and ',daily' or ''))

weather_widget = wibox.widget {
    {
        {
            id = 'icon',
            resize = true,
            widget = wibox.widget.imagebox
        },
        valign = 'center',
        widget = wibox.container.place,
    },
    {
        id = 'txt',
        font = font_name .. ' 8',
        align = 'center',
        widget = wibox.widget.textbox
    },
    layout = wibox.layout.fixed.vertical,
    set_image = function(self, path)
        self:get_children_by_id('icon')[1].image = path
    end,
    set_text = function(self, text)
        self:get_children_by_id('txt')[1].text = text
    end,
    is_ok = function(self, is_ok)
        if is_ok then
            self:get_children_by_id('icon')[1]:set_opacity(1)
            self:get_children_by_id('icon')[1]:emit_signal('widget:redraw_needed')
        else
            self:get_children_by_id('icon')[1]:set_opacity(0.2)
            self:get_children_by_id('icon')[1]:emit_signal('widget:redraw_needed')
        end
    end
}

local current_weather_widget = wibox.widget {
    {
        {
            {
                id = 'icon',
                resize = true,
                forced_width = dpi(100),
                forced_height = dpi(100),
                widget = wibox.widget.imagebox
            },
            align = 'center',
            widget = wibox.container.place
        },
        {
            id = 'description',
            font = font_name .. ' 10',
            align = 'center',
            widget = wibox.widget.textbox
        },
        forced_width = 128,
        layout = wibox.layout.align.vertical
    },
    {
        {
            {
                id = 'temp',
                font = font_name .. ' 34',
                widget = wibox.widget.textbox
            },
            {
                id = 'feels_like_temp',
                align = 'center',
                font = font_name .. ' 9',
                widget = wibox.widget.textbox
            },
            layout = wibox.layout.fixed.vertical
        },
        {
            {
                id = 'wind',
                font = font_name .. ' 9',
                widget = wibox.widget.textbox
            },
            {
                id = 'humidity',
                font = font_name .. ' 9',
                widget = wibox.widget.textbox
            },
            {
                id = 'uv',
                font = font_name .. ' 9',
                widget = wibox.widget.textbox
            },
            expand = 'inside',
            layout = wibox.layout.align.vertical
        },
        spacing = 16,
        forced_width = 150,
        layout = wibox.layout.fixed.vertical
    },
    forced_width = popup_width,
    layout = wibox.layout.flex.horizontal,
    update = function(self, weather)
        self:get_children_by_id('icon')[1]:set_image(
            icons_dir .. icon_map[weather.weather[1].icon] .. icons_extension)
        self:get_children_by_id('temp')[1]:set_text(gen_temperature_str(weather.temp, '%.0f', false, units))
        self:get_children_by_id('feels_like_temp')[1]:set_text(
            'Feels like ' .. gen_temperature_str(weather.feels_like, '%.0f', false, units))
        self:get_children_by_id('description')[1]:set_text(weather.weather[1].description)
        self:get_children_by_id('wind')[1]:set_markup(
            'Wind: <b>' .. weather.wind_speed .. 'm/s (' .. to_direction(weather.wind_deg) .. ')</b>')
        self:get_children_by_id('humidity')[1]:set_markup('Humidity: <b>' .. weather.humidity .. '%</b>')
        self:get_children_by_id('uv')[1]:set_markup('UV: ' .. uvi_index_color(weather.uvi))
    end
}


local daily_forecast_widget = {
    --forced_width = 300,
    layout = wibox.layout.flex.horizontal,
    update = function(self, forecast, timezone_offset)
        local count = #self
        for i = 0, count do self[i]=nil end
        for i, day in ipairs(forecast) do
            if i > 5 then break end
            local day_forecast = wibox.widget {
                {
                    text = os.date('%a', tonumber(day.dt) + tonumber(timezone_offset)),
                    align = 'center',
                    font = font_name .. ' 9',
                    widget = wibox.widget.textbox
                },
                {
                    {
                        {
                            image = icons_dir .. icon_map[day.weather[1].icon] .. icons_extension,
                            resize = true,
                            forced_width = dpi(30),
                            forced_height = dpi(30),
                            widget = wibox.widget.imagebox
                        },
                        align = 'center',
                        layout = wibox.container.place
                    },
                    {
                        text = day.weather[1].description,
                        font = font_name .. ' 8',
                        align = 'center',
                        forced_height = 50,
                        widget = wibox.widget.textbox
                    },
                    layout = wibox.layout.fixed.vertical
                },
                {
                    {
                        text = gen_temperature_str(day.temp.day, '%.0f', false, units),
                        align = 'center',
                        font = font_name .. ' 9',
                        widget = wibox.widget.textbox
                    },
                    {
                        text = gen_temperature_str(day.temp.night, '%.0f', false, units),
                        align = 'center',
                        font = font_name .. ' 9',
                        widget = wibox.widget.textbox
                    },
                    layout = wibox.layout.fixed.vertical
                },
                spacing = 8,
                layout = wibox.layout.fixed.vertical
            }
            table.insert(self, day_forecast)
        end
    end
}

local graph_height = dpi(50)

local hourly_forecast_graph = wibox.widget {
    step_width = popup_width / 25,
    color = '#EBCB8B',
    background_color = beautiful.bg_normal,
    forced_height = graph_height,
    forced_width = popup_width,
    widget = wibox.widget.graph,
    set_max_value = function(self, new_max_value)
        self.max_value = new_max_value
    end,
    set_min_value = function(self, new_min_value)
        self.min_value = new_min_value
    end
}

local hourly_forecast_negative_graph = wibox.widget {
    step_width = popup_width / 25,
    color = '#5E81AC',
    background_color = beautiful.bg_normal,
    forced_height = graph_height,
    forced_width = popup_width,
    widget = wibox.widget.graph,
    set_max_value = function(self, new_max_value)
        self.max_value = new_max_value
    end,
    set_min_value = function(self, new_min_value)
        self.min_value = new_min_value
    end
}

local hourly_forecast_widget = {
    layout = wibox.layout.fixed.vertical,
    update = function(self, hourly)
        local hours_below = {
            id = 'hours',
            forced_width = popup_width,
            layout = wibox.layout.flex.horizontal
        }
        local temp_below = {
            id = 'temp',
            forced_width = popup_width,
            layout = wibox.layout.flex.horizontal
        }

        local max_temp = -1000
        local min_temp = 1000
        local values = {}
        for i, hour in ipairs(hourly) do
            if i > 25 then break end
            values[i] = hour.temp
            if max_temp < hour.temp then max_temp = hour.temp end
            if min_temp > hour.temp then min_temp = hour.temp end
            if (i - 1) % 5 == 0 then
                table.insert(hours_below, wibox.widget {
                    text = os.date(time_format_12h and '%I%p' or '%H:00', tonumber(hour.dt)),
                    align = 'center',
                    font = font_name .. ' 9',
                    widget = wibox.widget.textbox
                })
                table.insert(temp_below, wibox.widget {
                    markup = '<span >' .. string.format('%.0f', hour.temp) .. '°' .. '</span>',
                    align = 'center',
                    font = font_name .. ' 9',
                    widget = wibox.widget.textbox
                })
            end
        end

        hourly_forecast_graph:set_max_value(math.max(max_temp, math.abs(min_temp)))
        hourly_forecast_graph:set_min_value(min_temp > 0 and min_temp * 0.7 or 0) -- move graph a bit up

        hourly_forecast_negative_graph:set_max_value(math.abs(min_temp))
        hourly_forecast_negative_graph:set_min_value(max_temp < 0 and math.abs(max_temp) * 0.7 or 0)

        for _, value in ipairs(values) do
            if value >= 0 then
                hourly_forecast_graph:add_value(value)
                hourly_forecast_negative_graph:add_value(0)
            else
                hourly_forecast_graph:add_value(0)
                hourly_forecast_negative_graph:add_value(math.abs(value))
            end
        end

        local count = #self
        for i = 0, count do self[i]=nil end

        -- all temperatures are positive
        if min_temp > 0 then
            table.insert(self, wibox.widget{
                {
                    hourly_forecast_graph,
                    reflection = {horizontal = true},
                    widget = wibox.container.mirror
                },
                {
                    temp_below,
                    valign = 'bottom',
                    widget = wibox.container.place
                },
                id = 'graph',
                layout = wibox.layout.stack
            })
            table.insert(self, hours_below)

        -- all temperatures are negative
        elseif max_temp < 0 then
            table.insert(self, hours_below)
            table.insert(self, wibox.widget{
                {
                    hourly_forecast_negative_graph,
                    reflection = {horizontal = true, vertical = true},
                    widget = wibox.container.mirror
                },
                {
                    temp_below,
                    valign = 'top',
                    widget = wibox.container.place
                },
                id = 'graph',
                layout = wibox.layout.stack
            })

        -- there are both negative and positive temperatures
        else
            table.insert(self, wibox.widget{
                {
                    hourly_forecast_graph,
                    reflection = {horizontal = true},
                    widget = wibox.container.mirror
                },
                {
                    temp_below,
                    valign = 'bottom',
                    widget = wibox.container.place
                },
                id = 'graph',
                layout = wibox.layout.stack
            })
            table.insert(self, wibox.widget{
                {
                    hourly_forecast_negative_graph,
                    reflection = {horizontal = true, vertical = true},
                    widget = wibox.container.mirror
                },
                {
                    hours_below,
                    valign = 'top',
                    widget = wibox.container.place
                },
                id = 'graph',
                layout = wibox.layout.stack
            })
        end
    end
}

local function update_widget(widget, stdout, stderr)
    if stderr ~= '' then
        if not warning_shown then
            if (stderr ~= 'curl: (52) Empty reply from server'
            and stderr ~= 'curl: (28) Failed to connect to api.openweathermap.org port 443: Connection timed out'
            and stderr:find('^curl: %(18%) transfer closed with %d+ bytes remaining to read$') ~= nil
            ) then
                show_warning(stderr)
            end
            warning_shown = true
            widget:is_ok(false)
            tooltip:add_to_object(widget)

            widget:connect_signal('mouse::enter', function() tooltip.text = stderr end)
        end
        return
    end

    warning_shown = false
    tooltip:remove_from_object(widget)
    widget:is_ok(true)

    local result = json.decode(stdout)

    widget:set_image(icons_dir .. icon_map[result.current.weather[1].icon] .. icons_extension)
    widget:set_text(gen_temperature_str(result.current.temp, '%.0f', both_units_widget, units))

    current_weather_widget:update(result.current)

    local final_widget = {
        current_weather_widget,
        spacing = dpi(10),
        layout = wibox.layout.fixed.vertical
    }

    if show_hourly_forecast then
        hourly_forecast_widget:update(result.hourly)
        table.insert(final_widget, hourly_forecast_widget)
    end

    if show_daily_forecast then
        daily_forecast_widget:update(result.daily, result.timezone_offset)
        table.insert(final_widget, daily_forecast_widget)
    end

    weather_popup:setup({
        {
            final_widget,
            margins = dpi(6),
            widget = wibox.container.margin
        },
        bg = beautiful.bg_normal,
        widget = wibox.container.background
    })
end

weather_widget:buttons(awful.util.table.join(awful.button({}, 1, function()
        if weather_popup.visible then
            weather_popup.visible = not weather_popup.visible
        else
            weather_popup:move_next_to(mouse.current_widget_geometry)
        end
    end)))

watch(
    string.format(get_forecast_cmd, owm_one_cal_api),
    timeout,  -- API limit is 1k req/day; day has 1440 min; every 2 min is good
    update_widget,
    weather_widget
)

return weather_widget
