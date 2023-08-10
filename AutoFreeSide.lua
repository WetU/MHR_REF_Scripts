local Constants = _G.require("Constants.Constants");

local find_type_definition = Constants.sdk.find_type_definition;
local to_managed_object = Constants.sdk.to_managed_object;
local hook = Constants.sdk.hook;

local TRUE_POINTER = Constants.TRUE_POINTER;
--
local isOpenRewardWindow = false;

local function PreHook_doOpen(args)
	local GuiSideQuestOrder = to_managed_object(args[2]);
	GuiSideQuestOrder:set_field("StampDelayTime", 0.0);
	GuiSideQuestOrder:set_field("DecideDelay", 0.0);
end
hook(find_type_definition("snow.gui.GuiSideQuestOrder"):get_method("doOpen"), PreHook_doOpen);

local function PostHook_getReaward()
	isOpenRewardWindow = true;
end
hook(find_type_definition("snow.gui.fsm.questcounter.GuiQuestCounterFsmFreeSideQuestCheckAction"):get_method("getReaward(snow.quest.FreeMissionData, snow.quest.FreeMissionWork)"), nil, PostHook_getReaward);

local function PostHook_getDecideButtonTrg(retval)
	if isOpenRewardWindow == true then
		isOpenRewardWindow = false;
		return TRUE_POINTER;
	end

	return retval;
end
hook(Constants.type_definitions.StmGuiInput_type_def:get_method("getDecideButtonTrg(snow.StmInputConfig.KeyConfigType, System.Boolean)"), nil, PostHook_getDecideButtonTrg);