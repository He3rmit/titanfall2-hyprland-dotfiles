-- fade.lua - simple crossfade for mpvpaper
-- configurable fade duration in seconds
FADE_DURATION = 1.5  -- default fade duration

-- allow override via mpv script-opts
local opts = require 'mp.options'
opts.read_options(nil, FADE_DURATION)

local mp = require 'mp'

function fade_in()
    mp.set_property_native("opacity", 0)
    mp.add_periodic_timer(0.01, function(timer)
        local op = mp.get_property_number("opacity", 0)
        op = math.min(op + 0.01 / FADE_DURATION, 1)
        mp.set_property_native("opacity", op)
        if op >= 1 then
            timer:kill()
        end
    end)
end

function fade_out()
    mp.add_periodic_timer(0.01, function(timer)
        local op = mp.get_property_number("opacity", 1)
        op = math.max(op - 0.01 / FADE_DURATION, 0)
        mp.set_property_native("opacity", op)
        if op <= 0 then
            timer:kill()
        end
    end)
end

mp.register_script_message("fade_in", fade_in)
mp.register_script_message("fade_out", fade_out)
