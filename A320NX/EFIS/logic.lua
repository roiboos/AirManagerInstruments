img_add_fullscreen("efis.png")
snd_click = sound_add("click.wav")

BARO_MODE_QFE = 0
BARO_MODE_QNH = 1
BARO_MODE_STD = 2

BARO_HPA_HG  = 0
BARO_HPA_HPA = 1

ND_FILTER_NONE = 0
ND_FILTER_CSTR = 1
ND_FILTER_VOR  = 2
ND_FILTER_WPT  = 3
ND_FILTER_NDB  = 4
ND_FILTER_ARPT = 5

local baro_mode
local baro_hpa

text_baro = txt_add("", "font:AirbusFCU.ttf; size:32; color: #FFFA99; halign:left;", 87, 124, 130, 42)
text_baro_mode_qnh = txt_add("QNH", "font:Poppins-SemiBold.ttf; size:28; color: #FFFA99; halign:left;", 141, 95, 49, 22)
text_baro_mode_qfe = txt_add("QFE", "font:Poppins-SemiBold.ttf; size:28; color: #FFFA99; halign:left;", 95, 95, 49, 22)

function baro_pressure_changed_inhg(inHg)
    if baro_hpa == BARO_HPA_HG and baro_mode ~= BARO_MODE_STD then
        txt_set(text_baro, string.format("%.2f", var_round(inHg, 2)))
    end            
end

function baro_pressure_changed_hpa(hpa)
    if baro_hpa == BARO_HPA_HPA and baro_mode ~= BARO_MODE_STD then
        txt_set(text_baro, string.format("%.4s", var_round(hpa, 0)))
    end
end

-- Baro (hPa or hg)
img_knob_baro_hpa = img_add("switch_baro.png", 95,206,92,92)

switch_baro = switch_add(nil, nil, 85, 205, 100, 100, "CIRCULAIR", 
    function (pos, dir)
        fs2020_variable_write("L:XMLVAR_BARO_SELECTOR_HPA_1",  "Num", pos+dir)
    end)
    
function baro_hpa_changed(pos)
                if(pos >= 0 and pos <= 1) then
                    baro_hpa = pos
                    if baro_hpa == BARO_HPA_HG then 
                        request_callback(baro_pressure_changed_inhg)
                    else
                        request_callback(baro_pressure_changed_hpa)
                    end
                    switch_set_position(switch_baro, (var_round(pos,0)))             
                    rotate(img_knob_baro_hpa, (pos*84)-84,"LOG", 0.1)
                end
end

fs2020_variable_subscribe("L:XMLVAR_Baro_Selector_HPA_1", "Num", baro_hpa_changed)
request_callback(baro_hpa_changed)  

-- Baro pressure set
dial_baro = dial_add("btn_baro.png", 105, 223, 64, 64, function (direction)  
    if baro_mode < BARO_MODE_STD then
        if direction == 1 then
            fs2020_event("KOHLSMAN_INC")
        elseif direction == -1 then
            fs2020_event("KOHLSMAN_DEC")
        end
    end
end)

-- Baro mode (Std, QNH)
function baro_mode_changed(baro)
    baro_mode = baro
    visible(text_baro_mode_qnh, baro_mode == BARO_MODE_QNH)
    visible(text_baro_mode_qfe, baro_mode == BARO_MODE_QFE)
end

fs2020_variable_subscribe("L:XMLVAR_Baro1_Mode", "Num", baro_mode_changed)

function baro_std()
    baro_mode = baro_mode + 1;
    if baro_mode > BARO_MODE_STD then
        baro_mode = BARO_MODE_QNH
    end 
    if baro_mode == BARO_MODE_STD then
        txt_set(text_baro, "Std")
    end   
    fs2020_variable_write("L:XMLVAR_Baro1_Mode",  "Num", baro_mode)
    sound_play(snd_click)
end
                
btn_baro_mode = button_add(nil, nil, 120, 240, 30, 30, baro_std)

-- Flight director
img_indicator_fd = img_add("indicator_active.png", 80, 335, 43, 17)

function flight_director_active_changed(active)
    visible(img_indicator_fd, active)
end

fs2020_variable_subscribe("A:AUTOPILOT FLIGHT DIRECTOR ACTIVE", "Bool", flight_director_active_changed)

btn_fd_active = button_add(nil, nil, 68, 328, 67, 53, function()
    fs2020_event("TOGGLE_FLIGHT_DIRECTOR")
    sound_play(snd_click)
end)

-- LS
local ls_active

img_indicator_ls = img_add("indicator_active.png", 164, 335, 43, 17)

function ls_active_changed(active)
    ls_active = active
    visible(img_indicator_ls, active == 1)
end

fs2020_variable_subscribe("L:BTN_LS_1_FILTER_ACTIVE", "Num", ls_active_changed)

btn_ls_active = button_add(nil, nil, 150, 328, 67, 53, function()    
    fs2020_variable_write("L:BTN_LS_1_FILTER_ACTIVE", "Num", 1 - ls_active)
    sound_play(snd_click)
end)

-- ND Filter
img_indicator_cstr = img_add("indicator_active.png", 259, 74, 43, 17)
img_indicator_wpt = img_add("indicator_active.png", 343, 74, 43, 17)
img_indicator_vor = img_add("indicator_active.png", 429, 74, 43, 17)
img_indicator_ndb = img_add("indicator_active.png", 513, 74, 43, 17)
img_indicator_arpt = img_add("indicator_active.png", 595, 74, 43, 17)

local nd_filter_last = -1;

function nd_filter_active_changed(nd_filter)
    visible(img_indicator_cstr, nd_filter == 1)
    visible(img_indicator_vor, nd_filter == 2)
    visible(img_indicator_wpt, nd_filter == 3)
    visible(img_indicator_ndb, nd_filter == 4)
    visible(img_indicator_arpt, nd_filter == 5)
    nd_filter_last = nd_filter;
end

fs2020_variable_subscribe("L:A32NX_EFIS_L_OPTION", "Num", nd_filter_active_changed)

-- CSTR
btn_nd_filter_cstr = button_add(nil, nil, 246, 70, 67, 53, function()
    local val = 1;    
    if nd_filter_last == 1 then val = 0 end
    fs2020_variable_write("L:A32NX_EFIS_L_OPTION", "Num", val)
    sound_play(snd_click)
end)

-- WPT
btn_nd_filter_wpt = button_add(nil, nil, 331, 70, 67, 53, function()    
    local val = 3;    
    if nd_filter_last == 3 then val = 0 end
    fs2020_variable_write("L:A32NX_EFIS_L_OPTION", "Num", val)
    sound_play(snd_click)
end)

-- VOR
btn_nd_filter_vor = button_add(nil, nil, 415, 70, 67, 53, function()    
    local val = 2;    
    if nd_filter_last == 2 then val = 0 end
    fs2020_variable_write("L:A32NX_EFIS_L_OPTION", "Num", val)
    sound_play(snd_click)
end)

-- NDB
btn_nd_filter_ndb = button_add(nil, nil, 498, 70, 67, 53, function()    
    local val = 4;    
    if nd_filter_last == 4 then val = 0 end
    fs2020_variable_write("L:A32NX_EFIS_L_OPTION", "Num", val)
    sound_play(snd_click)
end)

-- ARPT
btn_nd_filter_arpt = button_add(nil, nil, 583, 70, 67, 53, function()    
    local val = 5;    
    if nd_filter_last == 5 then val = 0 end
    fs2020_variable_write("L:A32NX_EFIS_L_OPTION", "Num", val)
    sound_play(snd_click)
end)

-- ND Mode
img_knob_nd_mode = img_add("switch_nd.png", 286,170,110,110)

switch_nd_mode = switch_add(nil, nil, nil, nil, nil, 286, 170, 110, 110, "CIRCULAIR", 
    function (pos, dir)
        fs2020_variable_write("L:A32NX_EFIS_L_ND_MODE",  "Num", pos+dir)
    end)
    
function nd_mode_changed(pos)
                switch_set_position(switch_nd_mode, (var_round(pos,0)))             
                rotate(img_knob_nd_mode, (pos*45)-90,"LOG", 0.1)
end

fs2020_variable_subscribe("L:A32NX_EFIS_L_ND_MODE", "Num", nd_mode_changed)

-- ND Range
img_knob_nd_range = img_add("switch_nd.png", 512,170,110,110)

switch_nd_range = switch_add(nil, nil, nil, nil, nil, nil, 512, 170, 110, 110, "CIRCULAIR", 
    function (pos, dir)
        fs2020_variable_write("L:A32NX_EFIS_L_ND_RANGE",  "Num", pos+dir)
    end)
    
function nd_range_changed(pos)
                switch_set_position(switch_nd_range, (var_round(pos,0)))             
                rotate(img_knob_nd_range, (pos*45)-90,"LOG", 0.1)
end

fs2020_variable_subscribe("L:A32NX_EFIS_L_ND_RANGE", "Num", nd_range_changed)

-- ADF-VOR 1
local navaid_modes = {1, 0, 2}

switch_navaid1_mode = switch_add("switch_left.png", "switch_ctr.png", "switch_right.png", 283, 312, 113, 58, "CIRCULAIR", 
    function (pos, dir)
        index = pos + dir
        new_mode = navaid_modes[index+1]
        fs2020_variable_write("L:A32NX_EFIS_L_NAVAID_1_MODE",  "Num", new_mode)
    end)
    
function navaid1_changed(pos)
                realpos = navaid_modes[pos+1]
                switch_set_position(switch_navaid1_mode, var_round(realpos,0))             
end

fs2020_variable_subscribe("L:A32NX_EFIS_L_NAVAID_1_MODE", "Num", navaid1_changed)

-- ADF-VOR 2

switch_navaid2_mode = switch_add("switch_left.png", "switch_ctr.png", "switch_right.png", 512, 314, 113, 58, "CIRCULAIR", 
    function (pos, dir)
        new_mode2 = navaid_modes[pos+dir+1];
        fs2020_variable_write("L:A32NX_EFIS_L_NAVAID_2_MODE",  "Num", new_mode2)
    end)
    
function navaid2_changed(pos)
                realpos = navaid_modes[pos+1]
                switch_set_position(switch_navaid2_mode, var_round(realpos,0))             
end

fs2020_variable_subscribe("L:A32NX_EFIS_L_NAVAID_2_MODE", "Num", navaid2_changed)

-- Baro display
fs2020_variable_subscribe("A:KOHLSMAN SETTING HG:1", "inHg", baro_pressure_changed_inhg)

fs2020_variable_subscribe("A:KOHLSMAN SETTING MB:1", "Millibars", baro_pressure_changed_hpa)
    