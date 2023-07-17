local Constants = require("Constants.Constants");
if not Constants then
	return;
end
--
local getTrg_method = Constants.SDK.find_type_definition("snow.GameKeyboard.HardwareKeyboard"):get_method("getTrg(via.hid.KeyboardKey)"); -- static
--
local getQuestReturnTimerSec_method = Constants.type_definitions.QuestManager_type_def:get_method("getQuestReturnTimerSec");
local getTotalJoinNum_method = Constants.type_definitions.QuestManager_type_def:get_method("getTotalJoinNum");
local nextEndFlowToCameraDemo_method = Constants.type_definitions.QuestManager_type_def:get_method("nextEndFlowToCameraDemo");
local EndFlow_field = Constants.type_definitions.QuestManager_type_def:get_field("_EndFlow");

local EndFlow_type_def = EndFlow_field:get_type();
local EndFlow = {
	WaitEndTimer = EndFlow_type_def:get_field("WaitEndTimer"):get_data(nil),
	WaitFadeCameraDemo = EndFlow_type_def:get_field("WaitFadeCameraDemo"):get_data(nil),
	CameraDemo = EndFlow_type_def:get_field("CameraDemo"):get_data(nil),
	WaitFadeOut = EndFlow_type_def:get_field("WaitFadeOut"):get_data(nil)
};
--
local HOME_key = 36;
-- No Kill Cam
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.camera.DemoCamera.DemoCameraData_KillCamera"):get_method("Start(via.motion.MotionCamera, via.motion.TreeLayer, via.Transform, snow.camera.DemoCamera_UserData)"), Constants.SKIP_ORIGINAL);

-- BTH
local function PreHook_updateQuestEndFlow(args)
	local QuestManager = Constants.SDK.to_managed_object(args[2]);
	if QuestManager == nil then
		return;
	end

	local endFlow = EndFlow_field:get_data(QuestManager);
	if endFlow == nil then
		return;
	end

	if endFlow == EndFlow.WaitEndTimer then
		if Constants.checkQuestStatus(QuestManager, Constants.QuestStatus.Success) == true then
			if (getTrg_method:call(nil, HOME_key) == true and getTotalJoinNum_method:call(QuestManager) == 1) or getQuestReturnTimerSec_method:call(QuestManager) <= 0.005 then
				nextEndFlowToCameraDemo_method:call(QuestManager);
			end
		else
			if getTrg_method:call(nil, HOME_key) == true then
				QuestManager:set_field("_QuestEndFlowTimer", 0.0);
			end
		end

	elseif endFlow == EndFlow.CameraDemo then
		QuestManager:set_field("_QuestEndFlowTimer", 0.0);

	elseif endFlow == EndFlow.WaitFadeCameraDemo or endFlow == EndFlow.WaitFadeOut then
		Constants.ClearFade();
	end
end
Constants.SDK.hook(Constants.type_definitions.QuestManager_type_def:get_method("updateQuestEndFlow"), PreHook_updateQuestEndFlow);
--
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.GuiQuestEndBase"):get_method("isEndQuestEndStamp"), Constants.SKIP_ORIGINAL, Constants.Return_TRUE);