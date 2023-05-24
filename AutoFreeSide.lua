local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_hook = sdk.hook;

local DecideBtnTrg = sdk.to_ptr(1);
--
sdk_hook(sdk_find_type_definition("snow.gui.GuiSideQuestOrder"):get_method("doOpen"), function(args)
    local GuiSideQuestOrder = sdk.to_managed_object(args[2]);
    if GuiSideQuestOrder then
        GuiSideQuestOrder:set_field("StampDelayTime", 0.0);
        GuiSideQuestOrder:set_field("DecideDelay", 0.0);
    end
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