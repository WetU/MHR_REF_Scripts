local require = require;
local Constants = require("Constants.Constants");

local find_type_definition = Constants.sdk.find_type_definition;
local get_managed_singleton = Constants.sdk.get_managed_singleton;
local to_managed_object = Constants.sdk.to_managed_object;
local hook = Constants.sdk.hook;

local checkQuestStatus = Constants.checkQuestStatus;
local Success = Constants.QuestStatus.Success;

local checkKeyTrg = Constants.checkKeyTrg;
local Home_key = Constants.Keys.Home_key;

local ClearFade = Constants.ClearFade;

local RETURN_TRUE_func = Constants.RETURN_TRUE;
--
local DemoEnd_method = find_type_definition("snow.camera.DemoCamera"):get_method("DemoEnd");
--
local QuestManager_type_def = Constants.type_definitions.QuestManager_type_def;
local getQuestReturnTimerSec_method = QuestManager_type_def:get_method("getQuestReturnTimerSec");
local nextEndFlowToCameraDemo_method = QuestManager_type_def:get_method("nextEndFlowToCameraDemo");
local getQuestPlayerCount_method = QuestManager_type_def:get_method("getQuestPlayerCount");
local EndFlow_field = QuestManager_type_def:get_field("_EndFlow");

local EndFlow_type_def = EndFlow_field:get_type();
local EndFlow = {
	WaitEndTimer = EndFlow_type_def:get_field("WaitEndTimer"):get_data(nil),
	WaitFadeCameraDemo = EndFlow_type_def:get_field("WaitFadeCameraDemo"):get_data(nil),
	CameraDemo = EndFlow_type_def:get_field("CameraDemo"):get_data(nil),
	WaitFadeOut = EndFlow_type_def:get_field("WaitFadeOut"):get_data(nil)
};
-- Skip Kill Camera
local function skipKillCamera()
	DemoEnd_method:call(get_managed_singleton("snow.camera.DemoCamera"));
end
hook(find_type_definition("snow.camera.DemoCamera.DemoCameraData_KillCamera"):get_method("Update(via.motion.MotionCamera, via.motion.TreeLayer, via.Transform)"), skipKillCamera);

-- Skip End Flow
local function onWaitEndTimer(questManager)
	if checkQuestStatus(questManager, Success) == true then
		if getQuestReturnTimerSec_method:call(questManager) <= 0.005 or (checkKeyTrg(Home_key) == true and getQuestPlayerCount_method:call(questManager) == 1) then
			nextEndFlowToCameraDemo_method:call(questManager);
		end
	end
end

local function PreHook_updateQuestEndFlow(args)
	local QuestManager = to_managed_object(args[2]) or get_managed_singleton("snow.QuestManager");
	local endFlow = EndFlow_field:get_data(QuestManager);

	if endFlow == EndFlow.WaitEndTimer then
		onWaitEndTimer(QuestManager);

	elseif endFlow == EndFlow.CameraDemo then
		QuestManager:set_field("_QuestEndFlowTimer", 0.0);

	elseif endFlow == EndFlow.WaitFadeCameraDemo or endFlow == EndFlow.WaitFadeOut then
		ClearFade();
	end
end
hook(QuestManager_type_def:get_method("updateQuestEndFlow"), PreHook_updateQuestEndFlow);
hook(find_type_definition("snow.gui.GuiQuestEndBase"):get_method("isEndQuestEndStamp"), nil, RETURN_TRUE_func);