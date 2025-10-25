-- fade.lua for mpv (3 second dissolve)
local mp = require 'mp'
local timer = nil

local function set_opacity(v)
    if v < 0 then v = 0 end
    if v > 1 then v = 1 end
    mp.set_property("options/opacity", tostring(v))
end

local function run_fade(target, duration)
    if timer then timer:kill() end
    local steps = 50
    local step_time = duration / steps
    local start = tonumber(mp.get_property("options/opacity")) or 1.0
    local delta = (target - start) / steps
    local i = 0
    timer = mp.add_periodic_timer(step_time, function()
        i = i + 1
        local v = start + delta * i
        set_opacity(v)
        if i >= steps then
            timer:kill()
            timer = nil
        end
    end)
end

mp.register_script_message("fade_out", function() run_fade(0.0, 3.0) end)
mp.register_script_message("fade_in",  function() run_fade(1.0, 3.0) end)
