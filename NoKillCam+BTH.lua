local Constants = _G.require("Constants.Constants");

local find_type_definition = Constants.sdk.find_type_definition;
local get_managed_singleton = Constants.sdk.get_managed_singleton;
local to_managed_object = Constants.sdk.to_managed_object;
local hook = Constants.sdk.hook;

local checkKeyTrg = Constants.checkKeyTrg;
local Home = Constants.Keys.Home;

local ClearFade = Constants.ClearFade;

local RETURN_TRUE_func = Constants.RETURN_TRUE_func;
--
local DemoEnd_method = find_type_definition("snow.camera.DemoCamera"):get_method("DemoEnd");
--
local QuestManager_type_def = Constants.type_definitions.QuestManager_type_def;
local get_DeltaSec_method = QuestManager_type_def:get_method("get_DeltaSec");
local checkStatus_method = QuestManager_type_def:get_method("checkStatus(snow.QuestManager.Status)");
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

local Success = find_type_definition("snow.QuestManager.Status"):get_field("Success"):get_data(nil);
-- Skip Demo Camera
local function skipDemo()
	DemoEnd_method:call(get_managed_singleton("snow.camera.DemoCamera"));
end
hook(find_type_definition("snow.camera.DemoCamera.DemoCameraData_KillCamera"):get_method("Start(via.motion.MotionCamera, via.motion.TreeLayer, via.Transform, snow.camera.DemoCamera_UserData)"), nil, skipDemo);

-- Skip End Flow
local function onWaitEndTimer(questManager)
	if checkStatus_method:call(questManager, Success) == true and (get_DeltaSec_method:call(questManager) >= getQuestReturnTimerSec_method:call(questManager) or (checkKeyTrg(Home) == true and getQuestPlayerCount_method:call(questManager) == 1)) then
		nextEndFlowToCameraDemo_method:call(questManager);
	end
end

local function clearEndFlowTimer(questManager)
	questManager:set_field("_QuestEndFlowTimer", 0.0);
end

local function EndFlow_body(questManager)
	local endFlow = EndFlow_field:get_data(questManager);

	if endFlow == EndFlow.WaitEndTimer then
		onWaitEndTimer(questManager);

	elseif endFlow == EndFlow.CameraDemo then
		clearEndFlowTimer(questManager);

	elseif endFlow == EndFlow.WaitFadeCameraDemo or endFlow == EndFlow.WaitFadeOut then
		ClearFade();
	end
end

local QuestManager = nil;
local function PreHook_updateQuestEndFlow(args)
	QuestManager = to_managed_object(args[2]) or get_managed_singleton("snow.QuestManager");
	EndFlow_body(QuestManager);
end
local function PostHook_updateQuestEndFlow()
	EndFlow_body(QuestManager);
	QuestManager = nil;
end
hook(QuestManager_type_def:get_method("updateQuestEndFlow"), PreHook_updateQuestEndFlow, PostHook_updateQuestEndFlow);
hook(find_type_definition("snow.gui.GuiQuestEndBase"):get_method("isEndQuestEndStamp"), nil, RETURN_TRUE_func);