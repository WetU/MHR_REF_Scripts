local require = require;
local Constants = require("Constants.Constants");
if not Constants then
	return;
end
--
local settings = Constants.JSON.load_file("NoKillCam+BTH.json") or {
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
if settings.NoKillCam.disableKillCam == nil then
	settings.NoKillCam.disableKillCam = true;
end
if settings.BTH.autoSkipCountdown == nil then
	settings.BTH.autoSkipCountdown = false;
end
if settings.BTH.autoSkipPostAnim == nil then
	settings.BTH.autoSkipPostAnim = true;
end
if settings.BTH.enableKeyboard == nil then
	settings.BTH.enableKeyboard = true;
end
if settings.BTH.kbCDSkipKey == nil then
	settings.BTH.kbCDSkipKey = 36;
end
if settings.BTH.kbAnimSkipKey == nil then
	settings.BTH.kbAnimSkipKey = 35;
end
local BTH_ENABLED = settings.BTH.autoSkipCountdown or settings.BTH.autoSkipPostAnim or settings.BTH.enableKeyboard or false;
-- Common Cache
local EndFlow_field = Constants.type_definitions.QuestManager_type_def:get_field("_EndFlow");

local EndFlow_type_def = EndFlow_field:get_type();
local EndFlow = {
	["WaitEndTimer"] = EndFlow_type_def:get_field("WaitEndTimer"):get_data(nil),
	["CameraDemo"] = EndFlow_type_def:get_field("CameraDemo"):get_data(nil)
};
-- No Kill Cam Cache
local isEndWait_method = Constants.type_definitions.QuestManager_type_def:get_method("isEndWait"); -- retval
local EndCaptureFlag_field = Constants.type_definitions.QuestManager_type_def:get_field("_EndCaptureFlag");
local EndCaptureFlag_CaptureEnd = EndCaptureFlag_field:get_type():get_field("CaptureEnd"):get_data(nil);

local CameraType_DemoCamera = Constants.SDK.find_type_definition("snow.CameraManager.CameraType"):get_field("DemoCamera"):get_data(nil);
-- BTH Cache
local getTotalJoinNum_method = Constants.type_definitions.QuestManager_type_def:get_method("getTotalJoinNum"); -- retval
local nextEndFlowToCameraDemo_method = Constants.type_definitions.QuestManager_type_def:get_method("nextEndFlowToCameraDemo");

local hardwareKeyboard_type_def = Constants.SDK.find_type_definition("snow.GameKeyboard.HardwareKeyboard");
local getTrg_method = hardwareKeyboard_type_def:get_method("getTrg(via.hid.KeyboardKey)"); -- static, retval
local getDown_method = hardwareKeyboard_type_def:get_method("getDown(via.hid.KeyboardKey)"); -- static, retval
--
local changeAllMarkerEnable_method = Constants.SDK.find_type_definition("snow.access.ObjectAccessManager"):get_method("changeAllMarkerEnable(System.Boolean)");
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
local function PreHook_RequestActive(args)
	if settings.NoKillCam.disableKillCam and (Constants.SDK.to_int64(args[3]) & 0xFFFFFFFF) == CameraType_DemoCamera then
		local QuestManager = Constants.SDK.get_managed_singleton("snow.QuestManager");
		if QuestManager and isEndWait_method:call(QuestManager) and EndFlow_field:get_data(QuestManager) <= EndFlow.WaitEndTimer and EndCaptureFlag_field:get_data(QuestManager) == EndCaptureFlag_CaptureEnd then
			return Constants.SDK.SKIP_ORIGINAL;
		end
	end
end
Constants.SDK.hook(Constants.type_definitions.CameraManager_type_def:get_method("RequestActive(snow.CameraManager.CameraType)"), PreHook_RequestActive);

-- BTH
local function getSkipTrg(skipType)
	if skipType == "Countdown" then
		return settings.BTH.autoSkipCountdown or (settings.BTH.enableKeyboard and getTrg_method:call(nil, settings.BTH.kbCDSkipKey)) or false;
	elseif skipType == "PostAnim" then
		return settings.BTH.autoSkipPostAnim or (settings.BTH.enableKeyboard and getTrg_method:call(nil, settings.BTH.kbAnimSkipKey)) or false;
	end
	return nil;
end

local QuestManager_obj = nil;
local function PreHook_updateQuestEndFlow(args)
	if BTH_ENABLED then
		QuestManager_obj = Constants.SDK.to_managed_object(args[2]);
	end
end
local function PostHook_updateQuestEndFlow()
	if QuestManager_obj then
		local endFlow = EndFlow_field:get_data(QuestManager_obj);
		if endFlow == EndFlow.WaitEndTimer and getTotalJoinNum_method:call(QuestManager_obj) == 1 and getSkipTrg("Countdown") then
			if settings.BTH.autoSkipPostAnim then
				nextEndFlowToCameraDemo_method:call(QuestManager_obj);
			else
				QuestManager_obj:set_field("_QuestEndFlowTimer", 0.0);
			end
		elseif endFlow == EndFlow.CameraDemo and getSkipTrg("PostAnim") then
			QuestManager_obj:set_field("_QuestEndFlowTimer", 0.0);
		end
    end
	QuestManager_obj = nil;
end
Constants.SDK.hook(Constants.type_definitions.QuestManager_type_def:get_method("updateQuestEndFlow"), PreHook_updateQuestEndFlow, PostHook_updateQuestEndFlow);

-- Remove Town Interaction Delay
local function PreHook_changeAllMarkerEnable(args)
	if (Constants.SDK.to_int64(args[3]) & 1) == 0 and Constants.checkStatus_None(nil) then
		local ObjectAccessManager = Constants.SDK.to_managed_object(args[2]);
		if ObjectAccessManager then
			changeAllMarkerEnable_method:call(ObjectAccessManager, true);
			return Constants.SDK.SKIP_ORIGINAL;
		end
	end
end
Constants.SDK.hook(changeAllMarkerEnable_method, PreHook_changeAllMarkerEnable);

-------------------------UI GARBAGE----------------------------------
local function SaveSettings()
	Constants.JSON.dump_file("NoKillCam+BTH.json", settings);
end

Constants.RE.on_config_save(SaveSettings);

local KeyboardKeys = require("bth.KeyboardKeys");
local drawSettings = false;
local setAnimSkipKey = false;
local setCDSkipKey = false;
local padBtnPrev = 0;
Constants.RE.on_draw_ui(function()
    if Constants.IMGUI.tree_node("No Kill-Cam + BTH") then
		local config_changed = false;
		local changed = false;
		config_changed, settings.NoKillCam.disableKillCam = Constants.IMGUI.checkbox("Disable KillCam", settings.NoKillCam.disableKillCam);
		Constants.IMGUI.spacing();
		if Constants.IMGUI.button("Fast Return Settings") then
			drawSettings = true;
		end
		if drawSettings then
			if Constants.IMGUI.begin_window("Fast Return Settings", true, 64) then
				if Constants.IMGUI.tree_node("~~Autoskip Settings~~") then
					changed, settings.BTH.autoSkipCountdown = Constants.IMGUI.checkbox('Autoskip Carve Timer', settings.BTH.autoSkipCountdown);
					config_changed = config_changed or changed;
					changed, settings.BTH.autoSkipPostAnim = Constants.IMGUI.checkbox('Autoskip Ending Anim.', settings.BTH.autoSkipPostAnim);
					config_changed = config_changed or changed;
					Constants.IMGUI.tree_pop();
				end

				if Constants.IMGUI.tree_node("~~Keyboard Settings~~") then
					changed, settings.BTH.enableKeyboard = Constants.IMGUI.checkbox("Enable Keyboard", settings.BTH.enableKeyboard);
					config_changed = config_changed or changed;
					if settings.BTH.enableKeyboard then
						Constants.IMGUI.text("Timer Skip");
						Constants.IMGUI.same_line();
						if Constants.IMGUI.button(KeyboardKeys[settings.BTH.kbCDSkipKey]) then
							setCDSkipKey = true;
							setAnimSkipKey = false;
						end
						Constants.IMGUI.text("Anim. Skip");
						Constants.IMGUI.same_line();
						if Constants.IMGUI.button(KeyboardKeys[settings.BTH.kbAnimSkipKey]) then
							setAnimSkipKey = true;
							setCDSkipKey = false;
						end
					end
					Constants.IMGUI.tree_pop();
				end

				if setCDSkipKey then
					settings.BTH.kbCDSkipKey = 0;
					for k, _ in Constants.LUA.pairs(KeyboardKeys) do
						if getDown_method:call(nil, k) then
							settings.BTH.kbCDSkipKey = k;
							setCDSkipKey = false;
							config_changed = true;
							break;
						end
					end
				elseif setAnimSkipKey then
					settings.BTH.kbAnimSkipKey = 0;
					for k, _ in Constants.LUA.pairs(KeyboardKeys) do
						if getDown_method:call(nil, k) then
							settings.BTH.kbAnimSkipKey = k;
							setAnimSkipKey = false;
							config_changed = true;
							break;
						end
					end
				end
				Constants.IMGUI.spacing();
				Constants.IMGUI.end_window();
			else
				drawSettings = false;
				setCDSkipKey = false;
				setAnimSkipKey = false;
			end
		end
		if config_changed then
			SaveSettings();
			BTH_ENABLED = settings.BTH.autoSkipCountdown or settings.BTH.autoSkipPostAnim or settings.BTH.enableKeyboard or false;
		end
        Constants.IMGUI.tree_pop();
    end
end);