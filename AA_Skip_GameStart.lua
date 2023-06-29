local Constants = require("Constants.Constants");
if not Constants then
	return;
end
--
local GuiGameStart_type_def = Constants.SDK.find_type_definition("snow.gui.fsm.title.GuiGameStart");
local stopReLogoMovie_method = GuiGameStart_type_def:get_method("stopReLogoMovie");

local notifyActionEnd_method = Constants.SDK.find_type_definition("via.behaviortree.ActionArg"):get_method("notifyActionEnd");
--
local function ClearAction(args)
    local Action = Constants.SDK.to_managed_object(args[3]);
    if Action ~= nil then
        notifyActionEnd_method:call(Action);
    end
end

local GuiGameStart = nil;
local function PreHook_reqPlayReLogoMovie(args)
    GuiGameStart = Constants.SDK.to_managed_object(args[2]);
end
local function PostHook_reqPlayReLogoMovie()
    if GuiGameStart ~= nil then
        stopReLogoMovie_method:call(GuiGameStart);
    end
    GuiGameStart = nil;
end

local function PreHook_OtherLogoFadeIn(args)
	local OtherLogoFadeIn = Constants.SDK.to_managed_object(args[2]);
	if OtherLogoFadeIn ~= nil then
		Constants.SDK.hook_vtable(OtherLogoFadeIn, OtherLogoFadeIn:get_type_definition():get_method("update(via.behaviortree.ActionArg)"), ClearAction, Constants.ClearFade);
	end
end

local function PreHook_getTitlePressAnyButton()
	return Constants.SDK.SKIP_ORIGINAL;
end
local function PostHook_getTitlePressAnyButton()
    return Constants.TRUE_POINTER;
end

Constants.SDK.hook(GuiGameStart_type_def:get_method("reqPlayReLogoMovie"), PreHook_reqPlayReLogoMovie, PostHook_reqPlayReLogoMovie);
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_CautionFadeIn"):get_method("start(via.behaviortree.ActionArg)"), nil, Constants.ClearFade);
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_CAPCOMLogoFadeIn"):get_method("start(via.behaviortree.ActionArg)"), nil, Constants.ClearFade);
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_RELogoFadeIn"):get_method("start(via.behaviortree.ActionArg)"), ClearAction, Constants.ClearFade);
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_OtherLogoFadeIn"):get_method("start(via.behaviortree.ActionArg)"), PreHook_OtherLogoFadeIn);
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_AutoSaveCaution_Action"):get_method("start(via.behaviortree.ActionArg)"), ClearAction);
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_HealthCautionFadeIn"):get_method("start(via.behaviortree.ActionArg)"), nil, Constants.ClearFade);
Constants.SDK.hook(Constants.type_definitions.StmGuiInput_type_def:get_method("getTitlePressAnyButton"), PreHook_getTitlePressAnyButton, PostHook_getTitlePressAnyButton);