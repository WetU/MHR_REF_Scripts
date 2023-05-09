---------------------------Settings----------------------
local settings = {
	NoKillCam = {
		disableKillCam = true,
	},
	BTH = {
		autoSkipCountdown = false,
		autoSkipPostAnim = true,
		enableKeyboard = true,
		kbCDSkipKey = 36,
		kbAnimSkipKey = 35
	}
};
----------------------------------------------------------
local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
local sdk_to_managed_object = sdk.to_managed_object;
local sdk_to_int64 = sdk.to_int64;
local sdk_hook = sdk.hook;
local sdk_SKIP_ORIGINAL = sdk.PreHookResult.SKIP_ORIGINAL;
local sdk_CALL_ORIGINAL = sdk.PreHookResult.CALL_ORIGINAL;

local re = re;
local re_on_draw_ui = re.on_draw_ui;
local re_on_config_save = re.on_config_save;

local imgui = imgui;
local imgui_tree_node = imgui.tree_node;
local imgui_checkbox = imgui.checkbox;
local imgui_tree_pop = imgui.tree_pop;
local imgui_button = imgui.button;
local imgui_begin_window = imgui.begin_window;
local imgui_text = imgui.text;
local imgui_same_line = imgui.same_line;
local imgui_spacing = imgui.spacing;
local imgui_end_window = imgui.end_window;

local json = json;
local json_load_file = json.load_file;
local json_dump_file = json.dump_file;

local require = require;
local pairs = pairs;

local loadedSettings = json_load_file("NoKillCam+BTH.json");
settings = loadedSettings or settings;

local function SaveSettings()
	json_dump_file("NoKillCam+BTH.json", settings);
end

-- Common Cache
local QuestManager_type_def = sdk_find_type_definition("snow.QuestManager");
local EndFlow_field = QuestManager_type_def:get_field("_EndFlow");

local EndFlow_type_def = EndFlow_field:get_type();
local EndFlow = {
	["Start"] = EndFlow_type_def:get_field("Start"):get_data(nil),
	["WaitEndTimer"] = EndFlow_type_def:get_field("WaitEndTimer"):get_data(nil),
	["CameraDemo"] = EndFlow_type_def:get_field("CameraDemo"):get_data(nil),
	["None"] = EndFlow_type_def:get_field("None"):get_data(nil)
};
-- No Kill Cam Cache
local EndCaptureFlag_field = QuestManager_type_def:get_field("_EndCaptureFlag");

local EndCaptureFlag_CaptureEnd = EndCaptureFlag_field:get_type():get_field("CaptureEnd"):get_data(nil);

local RequestActive_method = sdk_find_type_definition("snow.CameraManager"):get_method("RequestActive");
-- BTH Cache
local updateQuestEndFlow_method = QuestManager_type_def:get_method("updateQuestEndFlow");
local getQuestReturnTimerSec_method = QuestManager_type_def:get_method("getQuestReturnTimerSec");
local getTotalJoinNum_method = QuestManager_type_def:get_method("getTotalJoinNum");

local hardKeyboard_field = sdk_find_type_definition("snow.GameKeyboard"):get_field("hardKeyboard");

local hardwareKeyboard_type_def = hardKeyboard_field:get_type();
local getTrg_method = hardwareKeyboard_type_def:get_method("getTrg(via.hid.KeyboardKey)");
local getDown_method = hardwareKeyboard_type_def:get_method("getDown(via.hid.KeyboardKey)");
-- Remove Town Interaction Delay cache
local checkStatus_method = QuestManager_type_def:get_method("checkStatus(snow.QuestManager.Status)");
local changeAllMarkerEnable_method = sdk_find_type_definition("snow.access.ObjectAccessManager"):get_method("changeAllMarkerEnable(System.Boolean)");

local QuestStatus_None = sdk_find_type_definition("snow.QuestManager.Status"):get_field("None"):get_data(nil);
--[[
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
 16 == None;

QuestManager.CaptureStatus
 0 == Wait;
 1 == Request;
 2 == CaptureEnd;
]]--

-- No Kill Cam
sdk_hook(RequestActive_method, function(args)
	if settings.NoKillCam.disableKillCam and sdk_to_int64(args[3]) & 0xFFFFFFFF == 3 then --type 3 == 'demo' camera type
		local QuestManager = sdk_get_managed_singleton("snow.QuestManager");
		if QuestManager and EndFlow_field:get_data(QuestManager) <= EndFlow.WaitEndTimer and EndCaptureFlag_field:get_data(QuestManager) == EndCaptureFlag_CaptureEnd then
			return sdk_SKIP_ORIGINAL;
		end
	end
	return sdk_CALL_ORIGINAL;
end);

-- BTH
local QuestManager_obj = nil;
sdk_hook(updateQuestEndFlow_method, function(args)
	if settings.BTH.enableKeyboard or settings.BTH.autoSkipCountdown or settings.BTH.autoSkipPostAnim then
		QuestManager_obj = sdk_to_managed_object(args[2]);
	end
	return sdk_CALL_ORIGINAL;
end, function()
	if QuestManager_obj and getQuestReturnTimerSec_method:call(QuestManager_obj) > 1.0 then
		local endFlow = EndFlow_field:get_data(QuestManager_obj);
		if endFlow == EndFlow.WaitEndTimer and getTotalJoinNum_method:call(QuestManager_obj) == 1 then
			local requestCDSkip = settings.BTH.autoSkipCountdown;
			if not requestCDSkip and settings.BTH.enableKeyboard then
				local GameKeyboard_singleton = sdk_get_managed_singleton("snow.GameKeyboard");
				if GameKeyboard_singleton then
					local hwKB = hardKeyboard_field:get_data(GameKeyboard_singleton);
					if hwKB and getTrg_method:call(hwKB, settings.BTH.kbCDSkipKey) then
						requestCDSkip = true;
					end
				end
			end
			if requestCDSkip then
				QuestManager_obj:set_field("_QuestEndFlowTimer", 0.0);
			end
		elseif endFlow == EndFlow.CameraDemo then
			local requestAnimSkip = settings.BTH.autoSkipPostAnim;
			if not requestAnimSkip and settings.BTH.enableKeyboard then
				local GameKeyboard_singleton = sdk_get_managed_singleton("snow.GameKeyboard");
				if GameKeyboard_singleton then
					local hwKB = hardKeyboard_field:get_data(GameKeyboard_singleton);
					if hwKB and getTrg_method:call(hwKB, settings.BTH.kbAnimSkipKey) then
						requestAnimSkip = true;
					end
				end
			end
			if requestAnimSkip then
				QuestManager_obj:set_field("_QuestEndFlowTimer", 0.0);
			end
		end
    end
	QuestManager_obj = nil;
end);

-- Remove Town Interaction Delay
sdk_hook(changeAllMarkerEnable_method, function(args)
	if (sdk_to_int64(args[3]) & 1) ~= 1 then
		local QuestManager = sdk_get_managed_singleton("snow.QuestManager");
		if QuestManager and checkStatus_method:call(QuestManager, QuestStatus_None) then
			return sdk_SKIP_ORIGINAL;
		end
	end
	return sdk_CALL_ORIGINAL;
end);

-------------------------UI GARBAGE----------------------------------
local KeyboardKeys = require("bth.KeyboardKeys");
local drawSettings = false;
local setAnimSkipKey = false;
local setCDSkipKey = false;
local padBtnPrev = 0;
re_on_draw_ui(function()
	local changed = false;
    if imgui_tree_node("No Kill-Cam + BTH") then
		changed, settings.NoKillCam.disableKillCam = imgui_checkbox("Disable KillCam", settings.NoKillCam.disableKillCam);
		imgui_spacing();
		if imgui_button("Fast Return Settings") then
			drawSettings = true;
		end
		if drawSettings then
			if imgui_begin_window("Fast Return Settings", true, 64) then
				if imgui_tree_node("~~Autoskip Settings~~") then
					changed, settings.BTH.autoSkipCountdown = imgui_checkbox('Autoskip Carve Timer', settings.BTH.autoSkipCountdown);
					changed, settings.BTH.autoSkipPostAnim = imgui_checkbox('Autoskip Ending Anim.', settings.BTH.autoSkipPostAnim);
					imgui_tree_pop();
				end

				if imgui_tree_node("~~Keyboard Settings~~") then
					changed, settings.BTH.enableKeyboard = imgui_checkbox("Enable Keyboard", settings.BTH.enableKeyboard);
					if settings.BTH.enableKeyboard then
						imgui_text("Timer Skip");
						imgui_same_line();
						if imgui_button(KeyboardKeys[settings.BTH.kbCDSkipKey]) then
							setCDSkipKey = true;
							setAnimSkipKey = false;
						end
						imgui_text("Anim. Skip");
						imgui_same_line();
						if imgui_button(KeyboardKeys[settings.BTH.kbAnimSkipKey]) then
							setAnimSkipKey = true;
							setCDSkipKey = false;
						end
					end
					imgui_tree_pop();
				end

				if setCDSkipKey or setAnimSkipKey then
					local GameKeyboard_singleton = sdk_get_managed_singleton("snow.GameKeyboard");
					if GameKeyboard_singleton then
						local hwKB = hardKeyboard_field:get_data(GameKeyboard_singleton);
						if hwKB then
							if setCDSkipKey then
								settings.BTH.kbCDSkipKey = 0;
								for k, _ in pairs(KeyboardKeys) do
									if getDown_method:call(hwKB, k) then
										settings.BTH.kbCDSkipKey = k;
										SaveSettings();
										setCDSkipKey = false;
										break;
									end
								end
							elseif setAnimSkipKey then
								settings.BTH.kbAnimSkipKey = 0;
								for k, _ in pairs(KeyboardKeys) do
									if getDown_method:call(hwKB, k) then
										settings.BTH.kbAnimSkipKey = k;
										SaveSettings();
										setAnimSkipKey = false;
										break;
									end
								end
							end
						end
					end
				end
				imgui_spacing();
				imgui_end_window();
			else
				drawSettings = false;
				setCDSkipKey = false;
				setAnimSkipKey = false;
			end
		end
		if changed then
			SaveSettings();
		end
        imgui_tree_pop();
    end
end);

re_on_config_save(SaveSettings);