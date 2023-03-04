local require = require;
local pcall = pcall;
local pairs = pairs;

local math = math;
local math_floor = math.floor;

local json = json;
local json_dump_file = nil;
local json_load_file = nil;

local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
local sdk_to_managed_object = sdk.to_managed_object;
local sdk_hook = sdk.hook;
local sdk_CALL_ORIGINAL = sdk.PreHookResult.CALL_ORIGINAL;

local re = re;
local re_on_frame = re.on_frame;
local re_on_pre_application_entry = re.on_pre_application_entry;
local re_on_draw_ui = re.on_draw_ui;
local re_on_config_save = re.on_config_save;

local imgui = imgui;
local imgui_button = imgui.button;
local imgui_begin_window = imgui.begin_window;
local imgui_checkbox = imgui.checkbox;
local imgui_tree_node = imgui.tree_node;
local imgui_tree_pop = imgui.tree_pop;
local imgui_text = imgui.text;
local imgui_same_line = imgui.same_line;
local imgui_slider_int = imgui.slider_int;
local imgui_slider_float = imgui.slider_float;
local imgui_spacing = imgui.spacing;
local imgui_end_window = imgui.end_window;

local settings = { 
    enableMsg = true,
    autoskipCountdown = false,
    autoskipPostAnim = true,
    enableKeyboard = true,
    enableController = true,
    kbCDSkipKey = 36,
    kbAnimSkipKey = 35,
    padCDSkipBtn = 4096,
    padAnimSkipBtn = 8192,
    win_x = 0,
    win_y = 0,
    win_size_x = 0.5,
    win_size_y = 0.5,
    text_x = 50,
    text_y = 50,
    text_size = 16
};

local jsonAvailable = json ~= nil;
if jsonAvailable then
    json_load_file = json.load_file;
    json_dump_file = json.dump_file;
    local loadedTable = json_load_file("bth_settings.json");
    if loadedTable then
        for key, _ in pairs(loadedTable) do
            settings[key] = loadedTable[key];
        end
        -- the lua equivalent of converting to int
        settings.kbCDSkipKey = math_floor(settings.kbCDSkipKey);
        settings.kbAnimSkipKey = math_floor(settings.kbAnimSkipKey);
        settings.padCDSkipBtn = math_floor(settings.padCDSkipBtn);
        settings.padAnimSkipBtn = math_floor(settings.padAnimSkipBtn);
    end
end

local function save_settings()
    if jsonAvailable then
        json_dump_file("bth_settings.json", settings);
    end
end

local PadKeys = require("bth.PadKeys");
local PlaystationKeys = require("bth.PlaystationKeys");
local XboxKeys = require("bth.XboxKeys");
local NintendoKeys = require("bth.NintendoKeys");
local KeyboardKeys = require("bth.KeyboardKeys");

-- UI drawing state toggles
local drawWin = nil;
local drawDone = false;
local drawSettings = false;

-- Settings logic state toggles
local setAnimSkipBtn = false;
local setCDSkipBtn = false;
local setAnimSkipKey = false;
local setCDSkipKey = false;

-- Input managers
local padType = 0;
local padKeyLUT = XboxKeys;

-- Quest manager/actual functionality toggles
local skipCountdown = false;
local skipPostAnim = false;

-- Cache
local hardKeyboard_field = sdk_find_type_definition("snow.GameKeyboard"):get_field("hardKeyboard");
local hardwareKeyboard_type_def = hardKeyboard_field:get_type();
local getTrg_method = hardwareKeyboard_type_def:get_method("getTrg(via.hid.KeyboardKey)");
local getDown_method = hardwareKeyboard_type_def:get_method("getDown(via.hid.KeyboardKey)");

local hard_field = sdk_find_type_definition("snow.Pad"):get_field("hard");
local padDevice_type_def = hard_field:get_type();
local andOn_method = padDevice_type_def:get_method("andOn(snow.Pad.Button)");
local get_on_method = padDevice_type_def:get_method("get_on");
local get_deviceKindDetails_method = padDevice_type_def:get_method("get_deviceKindDetails");

local questManager_type_def = sdk_find_type_definition("snow.QuestManager");
local updateQuestEndFlow_method = questManager_type_def:get_method("updateQuestEndFlow");
local EndFlow_field = questManager_type_def:get_field("_EndFlow");
local QuestEndFlowTimer_field = questManager_type_def:get_field("_QuestEndFlowTimer");

local EndFlow_type_def = sdk_find_type_definition("snow.QuestManager.EndFlow");
local EndFlow_Start = EndFlow_type_def:get_field("Start"):get_data(nil); -- 0
local EndFlow_WaitEndTimer = EndFlow_type_def:get_field("WaitEndTimer"):get_data(nil); -- 1
local EndFlow_CameraDemo = EndFlow_type_def:get_field("CameraDemo"):get_data(nil); -- 8
local EndFlow_None = EndFlow_type_def:get_field("None"):get_data(nil); -- 16

local get_FrameTimeMillisecond_method = sdk_find_type_definition("via.Application"):get_method("get_FrameTimeMillisecond");
local reqAddChatInfomation_method = sdk_find_type_definition("snow.gui.ChatManager"):get_method("reqAddChatInfomation(System.String, System.UInt32)");

-- Button code to label decoder
local function pad_btncode_to_label(keycode)
    label = "";
    for k, v in pairs(PadKeys) do
        if keycode & k > 0 and padKeyLUT[PadKeys[k]] ~= nil then
            label = label .. padKeyLUT[PadKeys[k]] .. "+";
        end
    end
    if #label > 0 then
        return label:sub(0, -2);
    end
    return "None";
end

-- Internal Timer Functions
local timer = 0;
local timerLen = 200; -- timer length in millisecs
local function timer_reset()
    timer = 0;
end

local function timer_tick()
    -- timer tick function, returns true if timerLen has been reached
    timer = timer + get_FrameTimeMillisecond_method:call(nil);
    if timer >= timerLen then
        timer_reset();
        return true;
    end
    return false;
end

-- Strings and update function
local padCDSkipLabel = nil;
local padAnimSkipLabel = nil;
local carve_str = nil;
local anim_str = nil;
local autoskip_str = nil;
local function update_strings()
    padCDSkipLabel = pad_btncode_to_label(settings.padCDSkipBtn);
    padAnimSkipLabel = pad_btncode_to_label(settings.padAnimSkipBtn);
    carve_str = "Skip Timer: ";
    anim_str = "Skip Anim.: ";
    autoskip_str = "Autoskip: ";
    if settings.enableKeyboard or settings.enableController then
        if settings.enableKeyboard then
            carve_str = carve_str .. KeyboardKeys[settings.kbCDSkipKey];
            anim_str = anim_str .. KeyboardKeys[settings.kbAnimSkipKey];
            if settings.enableController then
                carve_str = carve_str .. "/";
                anim_str = anim_str .. "/";
            end
        end
        if settings.enableController then
            carve_str = carve_str .. padCDSkipLabel;
            anim_str = anim_str .. padAnimSkipLabel;
        end
    else
        carve_str = carve_str .. "N/A";
        anim_str = anim_str .. "N/A";
    end

    if settings.autoskipCountdown or settings.autoskipPostAnim then
        if settings.autoskipCountdown then
            autoskip_str = autoskip_str .. "Timer";
            if settings.autoSkipPostAnim then
                autoskip_str = autoskip_str .. " & ";
            end
        end
        if settings.autoskipPostAnim then
            autoskip_str = autoskip_str .. "Anim.";
        end
    else
        autoskip_str = autoskip_str .. "Off";
    end
end
update_strings();

--[[ Event callback hook for behaviour updates
QuestManager.EndFlow
 0 == Start;
 1 == WaitEndTimer;
 2 == InitCameraDemo;
 3 == WaitFadeCameraDemo;
 4 == LoadCameraDemo;
 5 == LoadInitCameraDemo;
 6 == LoadWaitCameraDemo;
 7 == StartCameraDemo;
 8 == CameraDemo;
 9 == Stamp;
 10 == WaitFadeOut;
 11 == InitEventCut;
 12 == WaitLoadEventCut;
 13 == WaitPlayEventCut;
 14 == WaitEndEventCut;
 15 == End;
 16 == None;]]--
local QuestManager = nil;
local ChatManager = nil;
local hwKB = nil;
local hwPad = nil;
sdk_hook(updateQuestEndFlow_method, function(args)
    if settings.enableKeyboard or settings.enableController or settings.autoskipCountdown or settings.autoSkipPostAnim then
        QuestManager = sdk_to_managed_object(args[2]);
    end
    return sdk_CALL_ORIGINAL;
end, function()
    if QuestManager then
        local endFlow = EndFlow_field:get_data(QuestManager);
        local questTimer = QuestEndFlowTimer_field:get_data(QuestManager);
        if endFlow > EndFlow_Start and endFlow < EndFlow_None then
            if settings.enableKeyboard and (not hwKB or hwKB:get_reference_count() <= 1) then
                local GameKeyboard_singleton = sdk_get_managed_singleton("snow.GameKeyboard");
                if GameKeyboard_singleton then
                    hwKB = hardKeyboard_field:get_data(GameKeyboard_singleton);
                end
            end
            if settings.enableController and (not hwPad or hwPad:get_reference_count() <= 1) then
                local Pad_singleton = sdk_get_managed_singleton("snow.Pad");
                if Pad_singleton then
                    hwPad = hard_field:get_data(Pad_singleton);
                end
            end

            drawWin = ((hwKB and hwPad) and 3) or (hwPad and 2) or (hwKB and 1) or nil;

            if settings.enableMsg and not drawDone and questTimer < 59.0 then
                drawDone = true;
                if not ChatManager or ChatManager:get_reference_count() <= 1 then
                    ChatManager = sdk_get_managed_singleton("snow.gui.ChatManager");
                end
                if ChatManager then
                    reqAddChatInfomation_method:call(ChatManager, "<COL RED>    FAST RETURN</COL>" .. '\n' .. carve_str .. '\n' .. anim_str .. '\n' .. autoskip_str, 2289944406);
                end
            end
        else
            skipCountdown = false;
            skipPostAnim = false;
            drawWin = nil;
            drawDone = false;
        end
        if questTimer > 1.0 and ((endFlow == EndFlow_WaitEndTimer and (skipCountdown or settings.autoskipCountdown)) or (endFlow == EndFlow_CameraDemo and (skipPostAnim or settings.autoskipPostAnim))) then
            QuestManager:set_field("_QuestEndFlowTimer", 0.0);
        end
        QuestManager = nil;
    end
end);

re_on_pre_application_entry("UpdateBehavior", function()
    local deviceKindDetails = hwPad and get_deviceKindDetails_method:call(hwPad) or nil;
    if deviceKindDetails then
        if padType ~= deviceKindDetails then
            padType = deviceKindDetails;
            padkeyLUT = (padType < 10 and XboxKeys) or (padType > 15 and NintendoKeys) or PlaystationKeys;
        end
    else
        padKeyLUT = XboxKeys;
    end
end);

-- Quest Clear GUI
re_on_frame(function()
    if drawWin then
        skipPostAnim = (drawWin == 1 and getTrg_method:call(hwKB, settings.kbAnimSkipKey)) or (drawWin == 2 and andOn_method:call(hwPad, settings.padAnimSkipBtn)) or (drawWin == 3 and (getTrg_method:call(hwKB, settings.kbAnimSkipKey) or andOn_method:call(hwPad, settings.padAnimSkipBtn))) or false;
        skipCountdown = (drawWin == 1 and getTrg_method:call(hwKB, settings.kbCDSkipKey)) or (drawWin == 2 and andOn_method:call(hwPad, settings.padCDSkipBtn)) or (drawWin == 3 and (getTrg_method:call(hwKB, settings.kbCDSkipKey) or andOn_method:call(hwPad, settings.padCDSkipBtn))) or false;
    end
end);

re_on_config_save(save_settings);

local padBtnPrev = 0;
re_on_draw_ui(function()
   -- Puts a simple confirmation text into the main window
    if imgui_button("Fast Return Settings") then
        drawSettings = true;
    end

    if drawSettings then
        local winStr = 'Fast Return Settings';
        if imgui_begin_window(winStr, true, 64) then
            local changed = false;
            changed, settings.enableMsg = imgui_checkbox('Chat Message on Quest Clear', settings.enableMsg);
            if imgui_tree_node("~~Autoskip Settings~~") then
                changed, settings.autoskipCountdown = imgui_checkbox('Autoskip Carve Timer', settings.autoskipCountdown);
                changed, settings.autoskipPostAnim = imgui_checkbox('Autoskip Ending Anim.', settings.autoskipPostAnim);
                imgui_tree_pop();
            end

            if imgui_tree_node("~~Keyboard Settings~~") then
                changed, settings.enableKeyboard = imgui_checkbox("Enable Keyboard", settings.enableKeyboard);
                if settings.enableKeyboard then
                    if not hwKB or hwKB:get_reference_count() <= 1 then
                        local GameKeyboard_singleton = sdk_get_managed_singleton("snow.GameKeyboard");
                        if GameKeyboard_singleton then
                            hwKB = hardKeyboard_field:get_data(GameKeyboard_singleton);
                        end
                    end
                    imgui_text("Timer Skip");
                    imgui_same_line();
                    if imgui_button(KeyboardKeys[settings.kbCDSkipKey]) then
                        setCDSkipKey = true;
                        setAnimSkipKey = false;
                        setAnimSkipBtn = false;
                        setCDSkipBtn = false;
                    end
                    imgui_text("Anim. Skip");
                    imgui_same_line();
                    if imgui_button(KeyboardKeys[settings.kbAnimSkipKey]) then
                        setAnimSkipKey = true;
                        setCDSkipKey = false;
                        setAnimSkipBtn = false;
                        setCDSkipBtn = false;
                    end
                end
                imgui_tree_pop();
            end

            if imgui_tree_node("~~Controller Settings~~") then
                changed, settings.enableController = imgui_checkbox("Enable Controller", settings.enableController);
                if settings.enableController then
                    if not hwPad or hwPad:get_reference_count() <= 1 then
                        local Pad_singleton = sdk_get_managed_singleton("snow.Pad");
                        if Pad_singleton then
                            hwPad = hard_field:get_data(Pad_singleton);
                        end
                    end
                    imgui_text("Timer Skip");
                    imgui_same_line();
                    if imgui_button(padCDSkipLabel) then
                        setCDSkipBtn = true;
                        setAnimSkipBtn = false;
                        setCDSkipKey = false;
                        setAnimSkipKey = false;
                    end
                    imgui_text("Anim. Skip");
                    imgui_same_line();
                    if imgui_button(padAnimSkipLabel) then
                        setAnimSkipBtn = true;
                        setCDSkipBtn = false;
                        setCDSkipKey = false;
                        setAnimSkipKey = false;
                    end
                end
                imgui_tree_pop();
            end

            if changed then
                if not settings.enableMsg then
                    ChatManager = nil;
                end
                if not settings.enableKeyboard then
                    hwKB = nil;
                end
                if not settings.enableController then
                    hwPad = nil;
                end
                save_settings();
                update_strings();
            end

            if setCDSkipKey then
                settings.kbCDSkipKey = 0;
                for k, _ in pairs(KeyboardKeys) do  -- VERY DIRTY BUT get_trg doesn't work?
                    if getDown_method:call(hwKB, k) then
                        settings.kbCDSkipKey = k;
                        save_settings();
                        update_strings();
                        setCDSkipKey = false;
                        break;
                    end
                end
            elseif setAnimSkipKey then
                settings.kbAnimSkipKey = 0;
                for k, _ in pairs(KeyboardKeys) do
                    if getDown_method:call(hwKB, k) then
                        settings.kbAnimSkipKey = k;
                        save_settings();
                        update_strings();
                        setAnimSkipKey = false;
                        break;
                    end
                end
            elseif setCDSkipBtn then
                settings.padCDSkipBtn = 0;
                padCDSkipLabel = pad_btncode_to_label(settings.padCDSkipBtn);
                local padBtnPressed = get_on_method:call(hwPad); -- get held buttons
                if padBtnPressed > 0 then -- if they press anything
                    if padBtnPressed == padBtnPrev then -- is it a new combination?
                        if timer_tick() then -- start timer, wait for it to finish
                            settings.padCDSkipBtn = padBtnPressed; -- timer ran out, update settings
                            save_settings();  -- autosave
                            padCDSkipLabel = pad_btncode_to_label(settings.padCDSkipBtn);  -- decoding btn label
                            update_strings();
                            padBtnPrev = 0;  -- resetting button 'memory'
                            setCDSkipBtn = false; -- done setting this button
                        end
                    else -- not a new combo
                        padBtnPrev = padBtnPressed; -- save this combo for a bit
                        timer_reset();
                    end
                end
            elseif setAnimSkipBtn then
                settings.padAnimSkipBtn = 0;
                -- checking if held button changed
                local padBtnPressed = get_on_method:call(hwPad); -- get held buttons
                if padBtnPressed > 0 then -- if they press anything
                    padAnimSkipLabel = pad_btncode_to_label(settings.padAnimSkipBtn);
                    if padBtnPressed == padBtnPrev then -- is it a new combination?
                        if timer_tick() then -- start timer, wait for it to finish
                            settings.padAnimSkipBtn = padBtnPressed; -- timer ran out, update settings
                            save_settings();  -- autosave
                            padAnimSkipLabel = pad_btncode_to_label(settings.padAnimSkipBtn);  -- decoding btn label
                            update_strings();
                            padBtnPrev = 0;  -- resetting button 'memory'
                            setAnimSkipBtn = false; -- done setting this button
                        end
                    else -- not a new combo
                        padBtnPrev = padBtnPressed; -- save this combo for a bit
                        timer_reset();
                    end
                end 
            end
            imgui_spacing();
            imgui_end_window();
        else
            drawSettings = false;
            setCDSkipBtn = false;
            setAnimSkipBtn = false;
            setCDSkipKey = false;
            setAnimSkipKey = false;
        end
    end
end);