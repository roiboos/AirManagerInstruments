
local srep = string.rep

-- pad the left side
lpad =
	function (s, l, c)
		local res = srep(c or ' ', l - #s) .. s

		return res
	end

img_add_fullscreen("fcu.png")
snd_click = sound_add("click.wav")

local hdg_mode = 0
local spd_mode = 0
local alt_mode = 0
local button_hold_active = false

function button_press()
    button_held_timer_id = timer_start(500, 0, button_held)
end

function button_held()
    timer_stop(button_held_timer_id) --should already be stopped, but just in case.
    button_hold_active = true
end

-- HDG
function button_hdg_handler()
    timer_stop(button_held_timer_id)
    if button_hold_active then
        fs2020_event("AP_HDG_HOLD_OFF")
    else
        fs2020_event("AP_HDG_HOLD_ON")
    end
    sound_play(snd_click)
    button_hold_active = false;
end

dial_hdg = dial_add("knob_hdg.png", 308, 195, 62, 61, 2, function(direction)    
    if hdg_mode == 0 then
        if direction == 1 then
            fs2020_event("HEADING_BUG_INC")
        elseif direction == -1 then
            fs2020_event("HEADING_BUG_DEC")
        end
    end
end)

btn_hdg_mode = button_add(nil, nil, 320, 210, 30, 30, button_press, button_hdg_handler)

fs2020_variable_subscribe("L:A32NX_AUTOPILOT_HEADING_SELECTED", "Num", function(hdg)
    if hdg == -1 then hdg_mode = 1 else hdg_mode = 0 end
end)

-- SPD
dial_spd = dial_add(nil, 109, 195, 62, 61, function(direction)
    if(spd_mode == 0) then
        if direction == 1 then
            fs2020_event("AP_SPD_VAR_INC")
        elseif direction == -1 then
            fs2020_event("AP_SPD_VAR_DEC")
        end
    end
end)

function button_spd_handler()
    timer_stop(button_held_timer_id)
    if button_hold_active then
        spd_mode = 0
        fs2020_event("AP_AIRSPEED_ON")
    else
        spd_mode = 1
        fs2020_event("AP_AIRSPEED_OFF")
    end
    sound_play(snd_click)
    button_hold_active = false;
end

btn_spd_mode = button_add(nil, nil, 125, 210, 30, 30, button_press, button_spd_handler)

-- ALT

text_alt = txt_add("", "font:AirbusFCU.ttf; size:32; color: #FFFA99; halign:right;", 678, 63, 162, 42)

dial_alt = dial_add("knob_alt.png", 746, 195, 66, 67, function(direction)
    if alt_mode == 0 then
        if direction == 1 then
            fs2020_event("AP_ALT_VAR_INC")
        elseif direction == -1 then
            fs2020_event("AP_ALT_VAR_DEC")
        end
    end
end)

img_knob_alt_step = img_add("switch_step.png", 720, 180, 92, 92)

switch_alt_step = switch_add(nil, nil, 720, 168, 100, 30, "CIRCULAIR", 
    function (pos, dir)
        if pos+dir == 1 then 
            fs2020_event("A32NX.FCU_ALT_INCREMENT_SET", 1000)
        else
            fs2020_event("A32NX.FCU_ALT_INCREMENT_SET", 100)
        end
    end)

function alt_step_changed(step_size)
                if step_size == 1000 then pos = 1 else pos = 0 end
                switch_set_position(switch_alt_step, (var_round(pos,0)))             
                rotate(img_knob_alt_step, (pos*84)-84,"LOG", 0.1)
end

fs2020_variable_subscribe("L:XMLVAR_AUTOPILOT_ALTITUDE_INCREMENT", "Num", alt_step_changed)

function button_alt_handler()
    timer_stop(button_held_timer_id)
    if button_hold_active then
        alt_mode = 0
        fs2020_event("AP_ALT_HOLD_ON")
    else
        alt_mode = 1
        fs2020_event("AP_ALT_HOLD_OFF")
    end
    sound_play(snd_click)
    button_hold_active = false;
end

btn_alt_mode = button_add(nil, nil, 765, 215, 30, 30, button_press, button_alt_handler)

fs2020_variable_subscribe("AUTOPILOT ALTITUDE LOCK VAR:3", "Feet", function(alt)
    alt_text = lpad(string.format("%d", var_round(alt, 0)), 5, "0");
    txt_set(text_alt, alt_text)
end)


