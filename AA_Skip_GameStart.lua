local Constants = require("Constants.Constants");
if not Constants then
	return;
end
--
local isAutoSaveCaution = nil;
local function PostHook_AutoSaveCaution_Action_update()
    isAutoSaveCaution = true;
end

local function skipAutoSaveCaution(retval)
    if isAutoSaveCaution then
		isAutoSaveCaution = nil;
		return Constants.TRUE_POINTER;
	end
    return retval;
end

local function skipTitle()
    return Constants.TRUE_POINTER;
end
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_AutoSaveCaution_Action"):get_method("update(via.behaviortree.ActionArg)"), nil, PostHook_AutoSaveCaution_Action_update);
Constants.SDK.hook(Constants.type_definitions.StmGuiInput_type_def:get_method("getDecideButtonTrg(snow.StmInputConfig.KeyConfigType, System.Boolean)"), nil, skipAutoSaveCaution);
Constants.SDK.hook(Constants.type_definitions.StmGuiInput_type_def:get_method("getTitlePressAnyButton"), nil, skipTitle);
Constants.SDK.hook(Constants.type_definitions.StmGuiInput_type_def:get_method("getTitleDispSkipTrg"), nil, skipTitle);