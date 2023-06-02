local Constants = require("Constants.Constants");
if not Constants then
    return;
end
--
local isOpenRewardWindow = nil;

local function PreHook_doOpen(args)
    local GuiSideQuestOrder = Constants.SDK.to_managed_object(args[2]);
    if GuiSideQuestOrder then
        GuiSideQuestOrder:set_field("StampDelayTime", 0.0);
        GuiSideQuestOrder:set_field("DecideDelay", 0.0);
    end
end

local function PostHook_getReaward()
    isOpenRewardWindow = true;
end

local function PostHook_DecideTrg(retval)
    if isOpenRewardWindow then
        isOpenRewardWindow = nil;
        return Constants.TRUE_POINTER;
    end
    return retval;
end

Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.GuiSideQuestOrder"):get_method("doOpen"), PreHook_doOpen);
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.questcounter.GuiQuestCounterFsmFreeSideQuestCheckAction"):get_method("getReaward(snow.quest.FreeMissionData, snow.quest.FreeMissionWork)"), nil, PostHook_getReaward);
Constants.SDK.hook(Constants.type_definitions.StmGuiInput_type_def:get_method("getDecideButtonTrg(snow.StmInputConfig.KeyConfigType, System.Boolean)"), nil, PostHook_DecideTrg);