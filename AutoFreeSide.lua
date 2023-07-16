local Constants = require("Constants.Constants");
if not Constants then
    return;
end
--
local isOpenRewardWindow = false;

local function PreHook_doOpen(args)
    local GuiSideQuestOrder = Constants.SDK.to_managed_object(args[2]);
    if GuiSideQuestOrder == nil then
        return;
    end

    GuiSideQuestOrder:set_field("StampDelayTime", 0.0);
    GuiSideQuestOrder:set_field("DecideDelay", 0.0);
    isOpenRewardWindow = false;
end
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.GuiSideQuestOrder"):get_method("doOpen"), PreHook_doOpen);

local function PostHook_getReaward()
    isOpenRewardWindow = true;
end
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.questcounter.GuiQuestCounterFsmFreeSideQuestCheckAction"):get_method("getReaward(snow.quest.FreeMissionData, snow.quest.FreeMissionWork)"), nil, PostHook_getReaward);

local function PreHook_getDecideButtonTrg()
    return isOpenRewardWindow == true and Constants.SDK.SKIP_ORIGINAL or Constants.SDK.CALL_ORIGINAL;
end
local function PostHook_getDecideButtonTrg(retval)
    if isOpenRewardWindow == true then
        isOpenRewardWindow = false;
        return Constants.TRUE_POINTER;
    end
    return retval;
end
Constants.SDK.hook(Constants.type_definitions.StmGuiInput_type_def:get_method("getDecideButtonTrg(snow.StmInputConfig.KeyConfigType, System.Boolean)"), PreHook_getDecideButtonTrg, PostHook_getDecideButtonTrg);