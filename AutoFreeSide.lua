local Constants = require("Constants.Constants");
if not Constants then
    return;
end
--
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.GuiSideQuestOrder"):get_method("doOpen"), function(args)
    local GuiSideQuestOrder = Constants.SDK.to_managed_object(args[2]);
    if GuiSideQuestOrder then
        GuiSideQuestOrder:set_field("StampDelayTime", 0.0);
        GuiSideQuestOrder:set_field("DecideDelay", 0.0);
    end
end);

local isOpenRewardWindow = nil;
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.questcounter.GuiQuestCounterFsmFreeSideQuestCheckAction"):get_method("getReaward(snow.quest.FreeMissionData, snow.quest.FreeMissionWork)"), nil, function()
    isOpenRewardWindow = true;
end);

Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.StmGuiInput"):get_method("getDecideButtonTrg(snow.StmInputConfig.KeyConfigType, System.Boolean)"), nil, function(retval)
    if isOpenRewardWindow then
        isOpenRewardWindow = nil;
        return Constants.TRUE_POINTER;
    end
    return retval;
end);