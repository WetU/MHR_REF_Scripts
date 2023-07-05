local require = require;
local Constants = require("Constants.Constants");
if not Constants then
	return;
end
-- Common Cache
local EndFlow_field = Constants.type_definitions.QuestManager_type_def:get_field("_EndFlow");

local EndFlow_type_def = EndFlow_field:get_type();
local EndFlow = {
	["WaitEndTimer"] = EndFlow_type_def:get_field("WaitEndTimer"):get_data(nil),
	["WaitFadeCameraDemo"] = EndFlow_type_def:get_field("WaitFadeCameraDemo"):get_data(nil),
	["CameraDemo"] = EndFlow_type_def:get_field("CameraDemo"):get_data(nil),
	["WaitFadeOut"] = EndFlow_type_def:get_field("WaitFadeOut"):get_data(nil)
};
-- No Kill Cam Cache
local EndCaptureFlag_field = Constants.type_definitions.QuestManager_type_def:get_field("_EndCaptureFlag");
local EndCaptureFlag_CaptureEnd = EndCaptureFlag_field:get_type():get_field("CaptureEnd"):get_data(nil);

local CameraType_DemoCamera = Constants.SDK.find_type_definition("snow.CameraManager.CameraType"):get_field("DemoCamera"):get_data(nil);
-- BTH Cache
local getQuestReturnTimerSec_method = Constants.type_definitions.QuestManager_type_def:get_method("getQuestReturnTimerSec"); -- retval
local getTotalJoinNum_method = Constants.type_definitions.QuestManager_type_def:get_method("getTotalJoinNum"); -- retval
local nextEndFlowToCameraDemo_method = Constants.type_definitions.QuestManager_type_def:get_method("nextEndFlowToCameraDemo");

local getTrg_method = Constants.SDK.find_type_definition("snow.GameKeyboard.HardwareKeyboard"):get_method("getTrg(via.hid.KeyboardKey)"); -- static, retval
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
	if (Constants.SDK.to_int64(args[3]) & 0xFFFFFFFF) == CameraType_DemoCamera then
		local QuestManager = Constants.SDK.get_managed_singleton("snow.QuestManager");
		if QuestManager ~= nil and EndFlow_field:get_data(QuestManager) <= EndFlow.WaitEndTimer and EndCaptureFlag_field:get_data(QuestManager) == EndCaptureFlag_CaptureEnd then
			return Constants.SDK.SKIP_ORIGINAL;
		end
	end
end
Constants.SDK.hook(Constants.type_definitions.CameraManager_type_def:get_method("RequestActive(snow.CameraManager.CameraType)"), PreHook_RequestActive);

-- BTH
local QuestManager_obj = nil;
local function PreHook_updateQuestEndFlow(args)
	QuestManager_obj = Constants.SDK.to_managed_object(args[2]);
	if QuestManager_obj ~= nil and EndFlow_field:get_data(QuestManager_obj) == EndFlow.WaitEndTimer then
		if Constants.checkQuestStatus(QuestManager_obj, Constants.QuestStatus.Success) == true and getQuestReturnTimerSec_method:call(QuestManager_obj) <= 0.005 then
			nextEndFlowToCameraDemo_method:call(QuestManager_obj);
		end
    end
end
local function PostHook_updateQuestEndFlow()
	if QuestManager_obj ~= nil then
		local endFlow = EndFlow_field:get_data(QuestManager_obj);
		if endFlow == EndFlow.WaitEndTimer then
			if getTrg_method:call(nil, 36) == true then
				if Constants.checkQuestStatus(QuestManager_obj, Constants.QuestStatus.Success) == true then
					if getTotalJoinNum_method:call(QuestManager_obj) == 1 then
						nextEndFlowToCameraDemo_method:call(QuestManager_obj);
					end
				else
					QuestManager_obj:set_field("_QuestEndFlowTimer", 0.0);
				end
			end
		elseif endFlow == EndFlow.WaitFadeCameraDemo or endFlow == EndFlow.WaitFadeOut then
			Constants.ClearFade();
		elseif endFlow == EndFlow.CameraDemo then
			QuestManager_obj:set_field("_QuestEndFlowTimer", 0.0);
		end
    end
	QuestManager_obj = nil;
end
Constants.SDK.hook(Constants.type_definitions.QuestManager_type_def:get_method("updateQuestEndFlow"), PreHook_updateQuestEndFlow, PostHook_updateQuestEndFlow);

Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.GuiQuestEndBase"):get_method("isEndQuestEndStamp"), Constants.SKIP_ORIGINAL, Constants.Return_TRUE);