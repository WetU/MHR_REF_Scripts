local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_hook = sdk.hook;

local GuiSideQuestOrder_type_def = sdk_find_type_definition("snow.gui.GuiSideQuestOrder");

local questState_field = GuiSideQuestOrder_type_def:get_field("questState");
local questState_Free = questState_field:get_type():get_field("Free"):get_data(nil);
--
local DecideBtnTrg = sdk.to_ptr(1);
--
local GuiSideQuestOrder = nil;
sdk_hook(GuiSideQuestOrder_type_def:get_method("doOpen"), function(args)
    GuiSideQuestOrder = sdk.to_managed_object(args[2]);
end, function()
    if GuiSideQuestOrder and questState_field:get_data(GuiSideQuestOrder) == questState_Free then
        GuiSideQuestOrder:set_field("StampDelayTime", 0.0);
        GuiSideQuestOrder:set_field("DecideDelay", 0.0);
    end
    GuiSideQuestOrder = nil;
end);

local isOpenRewardWindow = nil;
sdk_hook(sdk_find_type_definition("snow.gui.fsm.questcounter.GuiQuestCounterFsmFreeSideQuestCheckAction"):get_method("getReaward(snow.quest.FreeMissionData, snow.quest.FreeMissionWork)"), nil, function()
    isOpenRewardWindow = true;
end);

sdk_hook(sdk_find_type_definition("snow.gui.StmGuiInput"):get_method("getDecideButtonTrg(snow.StmInputConfig.KeyConfigType, System.Boolean)"), nil, function(retval)
    if isOpenRewardWindow then
        isOpenRewardWindow = nil;
        return DecideBtnTrg;
    end
    return retval;
end);