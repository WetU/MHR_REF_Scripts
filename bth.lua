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

local re = re;
local re_on_frame = re.on_frame;
local re_on_pre_application_entry = re.on_pre_application_entry;
local re_on_draw_ui = re.on_draw_ui;

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
-- Persistent settings (defaults)
local screen_w, screen_h = nil, nil;
local settings = { 
    enableWin = true,
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
-- Persistence Functions
local jsonAvailable = json ~= nil;
if jsonAvailable == true then
    json_load_file = json.load_file;
    json_dump_file = json.dump_file;
    local loadedTable = json_load_file("bth_settings.json");
    if loadedTable ~= nil then
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
    if jsonAvailable == true then
        json_dump_file("bth_settings.json", settings);
    end
end

-- loading keycode dicts separate from main logic
local PadKeys = require("bth.PadKeys");
local PlaystationKeys = require("bth.PlaystationKeys");
local XboxKeys = require("bth.XboxKeys");
local NintendoKeys = require("bth.NintendoKeys");
local KeyboardKeys = require("bth.KeyboardKeys");

-- UI drawing state toggles
local drawWin = false;
local drawDone = false;
local drawSettings = false;

-- Settings logic state toggles
local setAnimSkipBtn = false;
local setCDSkipBtn = false;
local setAnimSkipKey = false;
local setCDSkipKey = false;
local setWinPos = false;

-- Input managers
local hwKB = nil;
local hwPad = nil;
local padType = 0;
local padKeyLUT = XboxKeys; -- most probable default

-- Quest manager/actual functionality toggles
local questManager = nil;
local skipCountdown = false;
local skipPostAnim = false;

local get_FrameTimeMillisecond_method = sdk_find_type_definition("via.Application"):get_method("get_FrameTimeMillisecond");

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
local padCDSkipLabel = pad_btncode_to_label(settings.padCDSkipBtn);
local padAnimSkipLabel = pad_btncode_to_label(settings.padAnimSkipBtn);

local carve_str = nil;
local anim_str = nil;
local autoskip_str = nil;

local function update_strings()
    padCDSkipLabel = pad_btncode_to_label(settings.padCDSkipBtn);
    padAnimSkipLabel = pad_btncode_to_label(settings.padAnimSkipBtn);
    carve_str = "Skip Timer: ";
    if settings.enableKeyboard or settings.enableController then
        -- carve_str = carve_str.." ("
        if settings.enableKeyboard then
            carve_str = carve_str..KeyboardKeys[settings.kbCDSkipKey];
        end
        
        if settings.enableKeyboard and settings.enableController then
            carve_str = carve_str.."/";
        end

        if settings.enableController then
            carve_str = carve_str..padCDSkipLabel;
        end
    else
        carve_str = carve_str.."N/A";
    end

    anim_str = "Skip Anim.: ";
    if settings.enableKeyboard or settings.enableController then
        -- anim_str = anim_str..": "
        if settings.enableKeyboard then
            anim_str = anim_str..KeyboardKeys[settings.kbAnimSkipKey];
        end
        if settings.enableKeyboard and settings.enableController then
            anim_str = anim_str.."/";
        end
        if settings.enableController then
            anim_str = anim_str..padAnimSkipLabel;
        end
    else
        anim_str = anim_str.."N/A";
    end

    autoskip_str = "Autoskip: ";
    if settings.autoskipCountdown or settings.autoskipPostAnim then
        if settings.autoskipCountdown then
            autoskip_str = autoskip_str.."Timer";
        end
        if settings.autoskipCountdown and settings.autoskipPostAnim then
            autoskip_str = autoskip_str.." & ";
        end
        if settings.autoskipPostAnim then
            autoskip_str = autoskip_str.."Anim.";
        end
    else
        autoskip_str = autoskip_str.."Off";
    end
end

update_strings() -- settings were loaded, need to update strings

-- chat message on clear
local chatManager = nil;
local reqAddChatInfomation_method = sdk_find_type_definition("snow.gui.ChatManager"):get_method("reqAddChatInfomation(System.String, System.UInt32)");
local function push_message()
    if not chatManager or chatManager:get_reference_count() <= 1 then
        chatManager = sdk_get_managed_singleton("snow.gui.ChatManager");
    end
    if chatManager ~= nil then
        local chat_msg = "<COL RED>    FAST RETURN</COL>" .. '\n' .. carve_str .. '\n' .. anim_str .. '\n' .. autoskip_str;
        reqAddChatInfomation_method:call(chatManager, chat_msg, 2289944406);
    end
end

-- Quest Clear GUI
local hardwareKeyboard_type_def = sdk_find_type_definition("snow.GameKeyboard.HardwareKeyboard");
local getTrg_method = hardwareKeyboard_type_def:get_method("getTrg(via.hid.KeyboardKey)");

local padDevice_type_def = sdk_find_type_definition("snow.Pad.Device");
local andOn_method = padDevice_type_def:get_method("andOn(snow.Pad.Button)");
re_on_frame(function()
    if not drawWin then
        return;
    end
    -- Listening for Anim skip key press
    if (getTrg_method:call(hwKB, settings.kbAnimSkipKey) and settings.enableKeyboard) or (andOn_method:call(hwPad, settings.padAnimSkipBtn) and settings.enableController) then
        skipPostAnim = true;
    end

    -- Listening for CD skip key press
    if (getTrg_method:call(hwKB, settings.kbCDSkipKey) and settings.enableKeyboard) or (andOn_method:call(hwPad, settings.padCDSkipBtn) and settings.enableController) then
        skipCountdown = true;
    end
end);

-- Event callback hook for behaviour updates
local GameKeyboard_singleton = nil;
local Pad_singleton = nil;
local questManager_type_def = sdk_find_type_definition("snow.QuestManager");
local EndFlow_field = questManager_type_def:get_field("_EndFlow");
local QuestEndFlowTimer_field = questManager_type_def:get_field("_QuestEndFlowTimer");

local hardKeyboard_field = sdk_find_type_definition("snow.GameKeyboard"):get_field("hardKeyboard");
local hard_field = sdk_find_type_definition("snow.Pad"):get_field("hard");

local get_deviceKindDetails_method = padDevice_type_def:get_method("get_deviceKindDetails");
re_on_pre_application_entry("UpdateBehavior", function() -- unnamed/inline function definition
    -- grabbing the quest manager
    if not questManager or questManager:get_reference_count() <= 1 then
        questManager = sdk_get_managed_singleton("snow.QuestManager");
        if not questManager then -- if still nothing then aborting
            return nil;
        end
    end

    -- grabbing the keyboard manager    
    if not hwKB then
        if not GameKeyboard_singleton or GameKeyboard_singleton:get_reference_count() <= 1 then
            GameKeyboard_singleton = sdk_get_managed_singleton("snow.GameKeyboard");
        end
        hwKB = hardKeyboard_field:get_data(GameKeyboard_singleton); -- getting hardware keyboard manager
    end
    -- grabbing the gamepad manager
    if not hwPad then
        if not Pad_singleton or Pad_singleton:get_reference_count() <= 1 then
            Pad_singleton = sdk_get_managed_singleton("snow.Pad");
        end
        hwPad = hard_field:get_data(Pad_singleton); -- getting hardware keyboard manager
        if hwPad then
            padType = get_deviceKindDetails_method:call(hwPad);
            if padType ~= nil then
                if padType < 10 then
                    padKeyLUT = XboxKeys;
                elseif padType > 15 then
                    padKeyLUT = NintendoKeys;
                else
                    padKeyLUT = PlaystationKeys;
                end
            else
                padKeyLUT = XboxKeys; -- defaulting to Xbox Keys
            end
        end
    end

    -- getting Quest End state
    -- 0: still in quest, 1: ending countdown, 8: ending animation, 16: quest over
    local endFlow = EndFlow_field:get_data(questManager);

    -- getting shared quest end state timer
    -- used for both 60/20sec carve timer and ending animation timing
    local questTimer = QuestEndFlowTimer_field:get_data(questManager);
    
    if endFlow > 0 and endFlow < 16 then
        -- enabling main window draw if in the quest ending state
        drawWin = true;
        if settings.enableMsg and not drawDone and questTimer < 59 then
            push_message();
            drawDone = true;
        end
    else
        -- disabling draw and resetting timer skip otherwise
        -- if skipCountdown is left set to true, every consequent carve timer will be skipped :(
        skipCountdown = false;
        skipPostAnim = false;
        drawWin = false;
    end

    if questTimer > 1.0 then
        -- Skipping the carve timer if selected
        if endFlow == 1 and (skipCountdown or settings.autoskipCountdown) then
            questManager:set_field("_QuestEndFlowTimer", 1.0);
        end

        -- Skipping the post anim if selected
        if endFlow == 8 and (skipPostAnim or settings.autoskipPostAnim) then
            questManager:set_field("_QuestEndFlowTimer", 1.0);
        end
    end
end);

-- Hook for when the main RE Framework window is being drawn
local getDown_method = hardwareKeyboard_type_def:get_method("getDown(via.hid.KeyboardKey)");
local get_on_method = padDevice_type_def:get_method("get_on");
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
            -- settings logic
            -- Keyboard stuff
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
            -- controller stuff
            elseif setCDSkipBtn then
                settings.padCDSkipBtn = 0;
                padCDSkipLabel = pad_btncode_to_label(settings.padCDSkipBtn);
                -- checking if held button changed
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

            changed, settings.enableMsg = imgui_checkbox('Chat Message on Quest Clear', settings.enableMsg);
            
            if imgui_tree_node("~~Autoskip Settings~~") then
                changed, settings.autoskipCountdown = imgui_checkbox('Autoskip Carve Timer', settings.autoskipCountdown);
                changed, settings.autoskipPostAnim = imgui_checkbox('Autoskip Ending Anim.', settings.autoskipPostAnim);
                imgui_tree_pop();
            end

            if imgui_tree_node("~~Keyboard Settings~~") then
                -- changed, value = imgui.checkbox("Enable Keyboard Controls (" .. KeyboardKeys[settings.kbCDSkipKey] .. "/" .. KeyboardKeys[settings.kbAnimSkipKey] .. ")", settings.enableKeyboard)
                changed, settings.enableKeyboard = imgui_checkbox("Enable Keyboard", settings.enableKeyboard);

                imgui_text("Timer Skip");
                imgui_same_line();
                if imgui_button(KeyboardKeys[settings.kbCDSkipKey]) then
                    setCDSkipKey = true;
                    -- setting other modes to inactive
                    setAnimSkipKey = false;
                    setAnimSkipBtn = false;
                    setCDSkipBtn = false;
                end
                -- imgui.same_line()
                imgui_text("Anim. Skip");
                imgui_same_line();
                if imgui_button(KeyboardKeys[settings.kbAnimSkipKey]) then
                    setAnimSkipKey = true;
                    -- setting other modes to inactive
                    setCDSkipKey = false;
                    setAnimSkipBtn = false;
                    setCDSkipBtn = false;
                end
                imgui_tree_pop();
            end

            if imgui_tree_node("~~Controller Settings~~") then
                -- changed, value = imgui.checkbox("Enable Controller Controls (" .. padCDSkipLabel .. "/" .. padAnimSkipLabel .. ")", settings.enableController)
                changed, settings.enableController = imgui_checkbox("Enable Controller", settings.enableController);

                imgui_text("Timer Skip");
                imgui_same_line();
                if imgui_button(padCDSkipLabel) then
                    setCDSkipBtn = true;
                    -- setting other modes to inactive
                    setAnimSkipBtn = false;
                    setCDSkipKey = false;
                    setAnimSkipKey = false;
                end
                -- imgui.same_line()
                imgui_text("Anim. Skip");
                imgui_same_line();
                if imgui_button(padAnimSkipLabel) then
                    setAnimSkipBtn = true;
                    -- setting other modes to inactive
                    setCDSkipBtn = false;
                    setCDSkipKey = false;
                    setAnimSkipKey = false;
                end
                imgui_tree_pop();
            end
            if changed then
                save_settings();
                update_strings();
            end
            imgui_spacing();
            imgui_end_window();
        else
            drawSettings = false;
            setCDSkipBtn = false;
            setAnimSkipBtn = false;
            setCDSkipKey = false;
            setAnimSkipKey = false;
            setWinPos = false;
        end
    end
end);