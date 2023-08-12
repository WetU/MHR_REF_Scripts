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

local EndFlow = {
	WaitEndTimer = 1,
	WaitFadeCameraDemo = 3,
	CameraDemo = 8,
	WaitFadeOut = 10
};

local Success = 3;
-- Skip Demo Camera
local function skipDemo()
	DemoEnd_method:call(get_managed_singleton("snow.camera.DemoCamera"));
end
hook(find_type_definition("snow.camera.DemoCamera.DemoCameraData_KillCamera"):get_method("Start(via.motion.MotionCamera, via.motion.TreeLayer, via.Transform, snow.camera.DemoCamera_UserData)"), nil, skipDemo);

-- Skip End Flow
local QuestManager = nil;
local function PreHook_updateQuestEndFlow(args)
	QuestManager = to_managed_object(args[2]) or get_managed_singleton("snow.QuestManager");
end
local function PostHook_updateQuestEndFlow()
	local endFlow = EndFlow_field:get_data(QuestManager);

	if endFlow == EndFlow.WaitEndTimer then
		if checkStatus_method:call(QuestManager, Success) == true and (get_DeltaSec_method:call(QuestManager) >= getQuestReturnTimerSec_method:call(QuestManager) or (checkKeyTrg(Home) == true and getQuestPlayerCount_method:call(QuestManager) == 1)) then
			nextEndFlowToCameraDemo_method:call(QuestManager);
		end

	elseif endFlow == EndFlow.CameraDemo then
		QuestManager:set_field("_QuestEndFlowTimer", 0.0);

	elseif endFlow == EndFlow.WaitFadeCameraDemo or endFlow == EndFlow.WaitFadeOut then
		ClearFade();
	end

	QuestManager = nil;
end
hook(QuestManager_type_def:get_method("updateQuestEndFlow"), PreHook_updateQuestEndFlow, PostHook_updateQuestEndFlow);
hook(find_type_definition("snow.gui.GuiQuestEndBase"):get_method("isEndQuestEndStamp"), nil, RETURN_TRUE_func);