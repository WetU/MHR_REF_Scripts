local Constants = require("Constants.Constants");
if not Constants then
	return;
end
--
local getQuestReturnTimerSec_method = Constants.type_definitions.QuestManager_type_def:get_method("getQuestReturnTimerSec");
local getTotalJoinNum_method = Constants.type_definitions.QuestManager_type_def:get_method("getTotalJoinNum");
local EndFlow_field = Constants.type_definitions.QuestManager_type_def:get_field("_EndFlow");
local EndCaptureFlag_field = Constants.type_definitions.QuestManager_type_def:get_field("_EndCaptureFlag");

local EndFlow_type_def = EndFlow_field:get_type();
local EndFlow = {
	WaitEndTimer = EndFlow_type_def:get_field("WaitEndTimer"):get_data(nil),
	WaitFadeCameraDemo = EndFlow_type_def:get_field("WaitFadeCameraDemo"):get_data(nil),
	CameraDemo = EndFlow_type_def:get_field("CameraDemo"):get_data(nil),
	WaitFadeOut = EndFlow_type_def:get_field("WaitFadeOut"):get_data(nil)
};

local CaptureEnd = EndCaptureFlag_field:get_type():get_field("CaptureEnd"):get_data(nil);

local DemoCameraType = Constants.SDK.find_type_definition("snow.CameraManager.CameraType"):get_field("DemoCamera"):get_data(nil);

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
]]--

-- No Kill Cam
local function skipKillCam(args)
	if (Constants.SDK.to_int64(args[3]) & 0xFFFFFFFF) == DemoCameraType then
		local QuestManager = Constants.SDK.get_managed_singleton("snow.QuestManager");
		if QuestManager ~= nil and EndFlow_field:get_data(QuestManager) <= EndFlow.WaitEndTimer and EndCaptureFlag_field:get_data(QuestManager) == CaptureEnd then
			return Constants.SDK.SKIP_ORIGINAL;
		end
	end
end
Constants.SDK.hook(Constants.type_definitions.CameraManager_type_def:get_method("RequestActive(snow.CameraManager.CameraType)"), skipKillCam);

-- BTH
local function PreHook_updateQuestEndFlow(args)
	local QuestManager = Constants.SDK.to_managed_object(args[2]);
	if QuestManager ~= nil then
		local endFlow = EndFlow_field:get_data(QuestManager);
		if endFlow == EndFlow.WaitEndTimer then
			if Constants.checkQuestStatus(QuestManager, Constants.QuestStatus.Success) == true then
				if (getTrg_method:call(nil, 36) == true and getTotalJoinNum_method:call(QuestManager) == 1) or getQuestReturnTimerSec_method:call(QuestManager) <= 0.005 then
					QuestManager:set_field("_EndFlow", EndFlow.WaitFadeOut);
					QuestManager:set_field("_QuestEndFlowTimer", 0.0);
				end
			else
				if getTrg_method:call(nil, 36) == true then
					QuestManager:set_field("_EndFlow", EndFlow.WaitFadeOut);
					QuestManager:set_field("_QuestEndFlowTimer", 0.0);
				end
			end

		elseif endFlow == EndFlow.WaitFadeCameraDemo then
			Constants.ClearFade();
			QuestManager:set_field("_EndFlow", EndFlow.WaitFadeOut);
			QuestManager:set_field("_QuestEndFlowTimer", 0.0);

		elseif endFlow == EndFlow.CameraDemo then
			QuestManager:set_field("_EndFlow", EndFlow.WaitFadeOut);
			QuestManager:set_field("_QuestEndFlowTimer", 0.0);

		elseif endFlow == EndFlow.WaitFadeOut then
			Constants.ClearFade();
			QuestManager:set_field("_QuestEndFlowTimer", 0.0);
		end
    end
end
Constants.SDK.hook(Constants.type_definitions.QuestManager_type_def:get_method("updateQuestEndFlow"), PreHook_updateQuestEndFlow);
--
local function PreHook_nextEndFlowToCameraDemo(args)
	local QuestManager = Constants.SDK.to_managed_object(args[2]);
	if QuestManager ~= nil then
		QuestManager:set_field("_EndFlow", EndFlow.WaitFadeOut);
		QuestManager:set_field("_QuestEndFlowTimer", 0.0);
		return Constants.SDK.SKIP_ORIGINAL;
	end
end
Constants.SDK.hook(Constants.type_definitions.QuestManager_type_def:get_method("nextEndFlowToCameraDemo"), PreHook_nextEndFlowToCameraDemo);
--
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.GuiQuestEndBase"):get_method("isEndQuestEndStamp"), Constants.SKIP_ORIGINAL, Constants.Return_TRUE);