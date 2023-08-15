local Constants = _G.require("Constants.Constants");

local find_type_definition = Constants.sdk.find_type_definition;
local get_managed_singleton = Constants.sdk.get_managed_singleton;
local hook = Constants.sdk.hook;

local checkKeyTrg = Constants.checkKeyTrg;
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

-- Skip Demo Camera
local function skipDemo()
	DemoEnd_method:call(get_managed_singleton("snow.camera.DemoCamera"));
end
hook(find_type_definition("snow.camera.DemoCamera.DemoCameraData_KillCamera"):get_method("Start(via.motion.MotionCamera, via.motion.TreeLayer, via.Transform, snow.camera.DemoCamera_UserData)"), nil, skipDemo);

-- Skip End Flow
local isQuestSuccess = nil;

local function PostHook_updateQuestEndFlow()
	local QuestManager = Constants:get_QuestManager();
	local endFlow = EndFlow_field:get_data(QuestManager);

	if endFlow ~= 1 then
		isQuestSuccess = nil;

		if endFlow == 8 then
			QuestManager:set_field("_QuestEndFlowTimer", 0.0);
	
		elseif endFlow == 3 or endFlow == 10 then
			ClearFade();
		end
	else
		if isQuestSuccess == nil then
			isQuestSuccess = checkStatus_method:call(QuestManager, 3);
		end

		if isQuestSuccess == true and (get_DeltaSec_method:call(QuestManager) >= getQuestReturnTimerSec_method:call(QuestManager) or (checkKeyTrg(36) == true and getQuestPlayerCount_method:call(QuestManager) == 1)) then
			nextEndFlowToCameraDemo_method:call(QuestManager);
		end
	end
end
hook(QuestManager_type_def:get_method("updateQuestEndFlow"), nil, PostHook_updateQuestEndFlow);
hook(find_type_definition("snow.gui.GuiQuestEndBase"):get_method("isEndQuestEndStamp"), nil, RETURN_TRUE_func);