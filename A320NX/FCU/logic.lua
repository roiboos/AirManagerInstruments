local srep = string.rep

-- pad the left side
lpad =
	function (s, l, c)
		local res = srep(c or ' ', l - #s) .. s

		return res
	end

img_add_fullscreen("fcu.png")
snd_click = sound_add("click.wav")

TRACK_MODE_VS = 0
TRACK_MODE_FPA = 1

local hdg_mode = 0
local spd_mode = 0
local alt_mode = 0
local vs_mode  = 0
local track_mode = 0
local button_hold_active = false

function button_press()
    button_held_timer_id = timer_start(500, 0, button_held)
end

function button_held()
    timer_stop(button_held_timer_id) --should already be stopped, but just in case.
    button_hold_active = true
end

-- HDG
image_dot_hdg = img_add("dot.png", 402, 63, 25, 28)

text_hdg = txt_add("---", "font:AirbusFCU.ttf; size:32; color: #FFFA99; halign:left;", 312, 64, 80, 42)

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

local show_hdg = 0
local show_hdg_dot = 0
local current_hdg = 0

function update_hdg()
    if current_hdg == -1 then hdg_mode = 1 else hdg_mode = 0 end
    if hdg_mode == 0 and show_hdg == 1 then
        hdg_text = lpad(string.format("%d", var_round(current_hdg, 0)), 3, "0")
    else
        hdg_text = "---"
    end
    visible(image_dot_hdg, show_hdg_dot == 1)
    txt_set(text_hdg, hdg_text)
end

fs2020_variable_subscribe("L:A320_FCU_SHOW_SELECTED_HEADING", "Num", function(show)
    show_hdg = show
    update_hdg()
end)

fs2020_variable_subscribe("L:A32NX_AUTOPILOT_HEADING_SELECTED", "Num", function(hdg)
    current_hdg = hdg;
    update_hdg()
end)

fs2020_variable_subscribe("L:A32NX_FCU_HDG_MANAGED_DOT", "Num", function(show)
    show_hdg_dot = show
    update_hdg()
end)

-- MACH
local current_spd_mach = false

text_spd_mode_spd = txt_add("SPD", "font:Poppins-SemiBold.ttf; size:30; color: #FFFA99; halign:left;", 120, 34, 70, 24)
text_spd_mode_mach = txt_add("MACH", "font:Poppins-SemiBold.ttf; size:30; color: #FFFA99; halign:left;", 164, 34, 70, 24)

btn_spd_mach = button_add(nil, nil, 26, 146, 57, 57, function()
    fs2020_event("A32NX.FCU_SPD_MACH_TOGGLE_PUSH")
end)

fs2020_variable_subscribe("AUTOPILOT MANAGED SPEED IN MACH", "Bool", function(spd_mach)
    current_spd_mach = spd_mach
    visible(text_spd_mode_spd, current_spd_mach == false)
    visible(text_spd_mode_mach, current_spd_mach)
end)

-- SPD
image_dot_spd = img_add("dot.png", 215, 63, 25, 28)

text_spd = txt_add("---", "font:AirbusFCU.ttf; size:32; color: #FFFA99; halign:left;", 126, 64, 80, 42)

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
        fs2020_event("AP_AIRSPEED_OFF")
    else
        fs2020_event("AP_AIRSPEED_ON")
    end
    sound_play(snd_click)
    button_hold_active = false;
end

btn_spd_mode = button_add(nil, nil, 125, 210, 30, 30, button_press, button_spd_handler)

fs2020_variable_subscribe("L:A32NX_AUTOPILOT_SPEED_SELECTED", "Number", function(spd)
    if spd == -1 then spd_mode = 1 else spd_mode = 0 end
    if(spd_mode == 0) then
        if current_spd_mach then
            spd_text = string.format("%1.2f", spd)
        else
            spd_text = lpad(string.format("%d", var_round(spd, 0)), 3, "0")
        end
    else
        spd_text = "---"
    end
    visible(image_dot_spd, spd_mode == 1)
    txt_set(text_spd, spd_text)
end)

fs2020_variable_subscribe("L:A32NX_FCU_SPD_MANAGED_DOT", "Number",
                          "L:A32NX_FCU_SPD_MANAGED_DASHES", "Number", function(spd_dot, spd_dashes)
    visible(image_dot_spd, spd_dot == 1)
    if spd_dashes == 1 then
        txt_set(text_spd, "---")
    end
end)

-- ALT
image_dot_alt = img_add("dot.png", 839, 63, 25, 28)
text_alt = txt_add("", "font:AirbusFCU.ttf; size:32; color: #FFFA99; halign:right;", 678, 63, 162, 42)
text_vs = txt_add("", "font:AirbusFCU.ttf; size:32; color: #FFFA99; halign:right;", 855, 64, 162, 42)

dial_alt = dial_add("knob_alt.png", 746, 195, 66, 67, function(direction)
    if direction == 1 then
        fs2020_event("AP_ALT_VAR_INC")
    elseif direction == -1 then
        fs2020_event("AP_ALT_VAR_DEC")
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
        fs2020_event("AP_ALT_HOLD_OFF")
    else
        alt_mode = 1        
        fs2020_event("AP_ALT_HOLD_ON")
    end    
    sound_play(snd_click)
    button_hold_active = false;
end

btn_alt_mode = button_add(nil, nil, 765, 215, 30, 30, button_press, button_alt_handler)

fs2020_variable_subscribe("AUTOPILOT ALTITUDE LOCK VAR:3", "Feet", function(alt)
    alt_text = lpad(string.format("%d", var_round(alt, 0)), 5, "0");
    txt_set(text_alt, alt_text)
end)

local current_alt_managed

fs2020_variable_subscribe("L:A32NX_FCU_VS_MANAGED", "Num", function(managed)
    visible(image_dot_alt, current_alt_managed == 1)
    if current_alt_managed == 1 then    
           txt_set(text_vs, "-----")
    else
        if track_mode == TRACK_MODE_VS then
            txt_set(text_vs, "0000")
        else
            txt_set(text_vs, "+0.0")
        end
    end
end)

fs2020_variable_subscribe("L:A32NX_FCU_ALT_MANAGED", "Number", function(managed)
    current_alt_managed = managed
    visible(image_dot_alt, managed == 1)
    if managed == 1 then 
        txt_set(text_vs, "-----")
    end
end)

-- V/S FPA
text_track_mode_vs = txt_add("V/S", "font:Poppins-SemiBold.ttf; size:30; color: #FFFA99; halign:left;", 930, 34, 70, 24)
text_track_mode_fpa = txt_add("FPA", "font:Poppins-SemiBold.ttf; size:30; color: #FFFA99; halign:left;", 977, 34, 70, 24)
text_track_mode_hdg = txt_add("HDG", "font:Poppins-SemiBold.ttf; size:30; color: #FFFA99; halign:left;", 496, 54, 70, 24)
text_track_mode_vs2 = txt_add("V/S", "font:Poppins-SemiBold.ttf; size:30; color: #FFFA99; halign:left;", 578, 54, 70, 24)
text_track_mode_trk = txt_add("TRK", "font:Poppins-SemiBold.ttf; size:30; color: #FFFA99; halign:left;", 496, 74, 70, 24)
text_track_mode_fpa2 = txt_add("FPA", "font:Poppins-SemiBold.ttf; size:30; color: #FFFA99; halign:left;", 578, 74, 70, 24)
text_track_mode_hdg2 = txt_add("HDG", "font:Poppins-SemiBold.ttf; size:30; color: #FFFA99; halign:left;", 307, 34, 70, 24)
text_track_mode_trk2 = txt_add("TRK", "font:Poppins-SemiBold.ttf; size:30; color: #FFFA99; halign:left;", 355, 34, 70, 24)

dial_vs = dial_add(nil, 972, 195, 62, 61, function(direction)
    if direction == 1 then
        fs2020_event("AP_VS_VAR_INC")
    elseif direction == -1 then
        fs2020_event("AP_VS_VAR_DEC")
    end
end)

fs2020_variable_subscribe("L:A32NX_TRK_FPA_MODE_ACTIVE", "Num", function(tm)
    track_mode = tm
    if current_alt_managed == 0 then
        if track_mode == TRACK_MODE_FPA then
            txt_set(text_vs, "+0.0")
        else
            txt_set(text_vs, "0000")
        end
    end
    visible(text_track_mode_vs, track_mode == TRACK_MODE_VS)
    visible(text_track_mode_fpa, track_mode == TRACK_MODE_FPA)
    visible(text_track_mode_vs2, track_mode == TRACK_MODE_VS)
    visible(text_track_mode_fpa2, track_mode == TRACK_MODE_FPA)    
    visible(text_track_mode_hdg, track_mode == TRACK_MODE_VS)
    visible(text_track_mode_trk, track_mode == TRACK_MODE_FPA)    
    visible(text_track_mode_hdg2, track_mode == TRACK_MODE_VS)
    visible(text_track_mode_trk2, track_mode == TRACK_MODE_FPA)    
end)

fs2020_variable_subscribe("L:A32NX_AUTOPILOT_VS_SELECTED", "Num", function(vs)
    if track_mode == TRACK_MODE_VS then
        vs_unsigned = vs; 
        sign  = "+";   
        if vs < 0 then
         sign = "-"
         vs_unsigned = vs * -1 
        elseif vs == 0 then
         sign = "";
        end
        vs_text = sign .. lpad(string.format("%d", var_round(vs_unsigned, 0)), 4, "0");
        if current_alt_managed then vs_text = "-----" end
        
        txt_set(text_vs, vs_text)
    end
end)

fs2020_variable_subscribe("L:A32NX_AUTOPILOT_FPA_SELECTED", "Num", function(fpa)
    if track_mode == TRACK_MODE_FPA then
        fpa_unsigned = fpa; 
        sign  = "+";   
        if fpa < 0 then
         sign = "-"
         fpa_unsigned = fpa * -1 
        elseif fpa == 0 then
         sign = "+";
        end
        fpa_text = sign .. string.format("%2.1f", var_round(fpa_unsigned, 2));
        if current_alt_managed then vs_text = "-----" end

        txt_set(text_vs, fpa_text)
    end
end)

btn_vs_fpa = button_add(nil, nil, 997, 216, 30, 30, function()
    fs2020_event("A32NX.FCU_VS_PUSH")
    sound_play(snd_click)    
end)

btn_track_mode = button_add(nil, nil, 533, 141, 60, 60, function(tm)
    fs2020_event("A32NX.FCU_TRK_FPA_TOGGLE_PUSH")
    sound_play(snd_click)
end)

-- AP1
img_indicator_ap1 = img_add("indicator_active.png", 488, 214, 43, 17)

fs2020_variable_subscribe("L:A32NX_AUTOPILOT_1_ACTIVE", "Num", function(active)
    visible(img_indicator_ap1, active)
end)

btn_ap1 = button_add(nil, nil, 475, 200, 69, 69, function()
    fs2020_event("A32NX.FCU_AP_1_PUSH")
    sound_play(snd_click)
end)

-- AP2
img_indicator_ap2 = img_add("indicator_active.png", 588, 214, 43, 17)

fs2020_variable_subscribe("L:A32NX_AUTOPILOT_2_ACTIVE", "Num", function(active)
    visible(img_indicator_ap2, active == 1)
end)

btn_ap2 = button_add(nil, nil, 578, 200, 69, 69, function()
    fs2020_event("A32NX.FCU_AP_2_PUSH")
    sound_play(snd_click)
end)

-- LOC
img_indicator_loc = img_add("indicator_active.png", 341, 337, 43, 17)

fs2020_variable_subscribe("L:A32NX_FCU_LOC_MODE_ACTIVE", "Num", function(active)
    visible(img_indicator_loc, active == 1)
end)

btn_loc = button_add(nil, nil, 330, 329, 63, 50, function()
    fs2020_event("A32NX.FCU_LOC_PUSH")
    sound_play(snd_click)
end)

-- EXPED
img_indicator_exped = img_add("indicator_active.png", 736, 337, 43, 17)

fs2020_variable_subscribe("L:A32NX_FMA_EXPEDITE_MODE", "Num", function(active)
    visible(img_indicator_exped, active == 1)
end)

btn_exped = button_add(nil, nil, 722, 329, 63, 50, function()
    fs2020_event("A32NX.FCU_EXPED_PUSH")
    sound_play(snd_click)
end)

-- APPR
img_indicator_appr = img_add("indicator_active.png", 965, 337, 43, 17)

fs2020_variable_subscribe("L:A32NX_FCU_APPR_MODE_ACTIVE", "Num", function(active)
    visible(img_indicator_appr, active == 1)
end)

btn_appr = button_add(nil, nil, 951, 329, 63, 50, function()
    fs2020_event("A32NX.FCU_APPR_PUSH")
    sound_play(snd_click)
end)

-- A/THR
img_indicator_athr = img_add("indicator_active.png", 537, 320, 43, 17)

fs2020_variable_subscribe("L:A32NX_AUTOTHRUST_STATUS", "Num", function(active)
    visible(img_indicator_athr, active > 0)
end)

btn_athr = button_add(nil, nil, 526, 309, 69, 69, function()
    fs2020_event("A32NX.FCU_ATHR_PUSH")
    sound_play(snd_click)
end)

-- METRIC ALT
local metric_alt_mode = 0

fs2020_variable_subscribe("L:A32NX_METRIC_ALT_TOGGLE", "Num", function(mode)
    metric_alt_mode = mode
end)

btn_metric_alt = button_add(nil, nil, 855, 146, 57, 57, function()
    local new_mode = 0
    if metric_alt_mode == 1 then 
        new_mode = 0
    else 
        new_mode = 1
    end
    fs2020_variable_write("L:A32NX_METRIC_ALT_TOGGLE", "Num", new_mode)
end)
