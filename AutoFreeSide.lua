local Constants = require("Constants.Constants");
if not Constants then
    return;
end
--
local config = Constants.JSON.load_file("AutoFreeSide.json") or {RemoveDelay = true, AutoReceive = true};
if config.RemoveDelay == nil then
    config.RemoveDelay = true;
end
if config.AutoReceive == nil then
    config.AutoReceive = true;
end
--
local isOpenRewardWindow = nil;

local function PreHook_doOpen(args)
    if config.RemoveDelay then
        local GuiSideQuestOrder = Constants.SDK.to_managed_object(args[2]);
        if GuiSideQuestOrder then
            GuiSideQuestOrder:set_field("StampDelayTime", 0.0);
            GuiSideQuestOrder:set_field("DecideDelay", 0.0);
        end
    end
    if config.AutoReceive then
        isOpenRewardWindow = nil;
    end
end
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.GuiSideQuestOrder"):get_method("doOpen"), PreHook_doOpen);

local function PostHook_getReaward()
    if config.AutoReceive then
        isOpenRewardWindow = true;
    end
end
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.questcounter.GuiQuestCounterFsmFreeSideQuestCheckAction"):get_method("getReaward(snow.quest.FreeMissionData, snow.quest.FreeMissionWork)"), nil, PostHook_getReaward);

local function PreHook_getDecideButtonTrg()
    if isOpenRewardWindow then
        return Constants.SDK.SKIP_ORIGINAL;
    end
end
local function PostHook_getDecideButtonTrg(retval)
    if isOpenRewardWindow then
        isOpenRewardWindow = nil;
        return Constants.TRUE_POINTER;
    end
    return retval;
end
Constants.SDK.hook(Constants.type_definitions.StmGuiInput_type_def:get_method("getDecideButtonTrg(snow.StmInputConfig.KeyConfigType, System.Boolean)"), PreHook_getDecideButtonTrg, PostHook_getDecideButtonTrg);
--
local function SaveSettings()
    Constants.JSON.dump_file("AutoFreeSide.json", config);
end

Constants.RE.on_config_save(SaveSettings);
Constants.RE.on_draw_ui(function()
    if Constants.IMGUI.tree_node("AutoFreeSide") then
        local config_changed = false;
        local changed = false;
		config_changed, config.RemoveDelay = Constants.IMGUI.checkbox("Remove delay", config.RemoveDelay);
        changed, config.AutoReceive = Constants.IMGUI.checkbox("Auto receive", config.AutoReceive);
        config_changed = config_changed or changed;
        if config_changed then
            SaveSettings();
        end
		Constants.IMGUI.tree_pop();
	end
end);