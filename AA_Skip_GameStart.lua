local Constants = require("Constants.Constants");
if not Constants then
	return;
end
--
local viaMovie_type_def = Constants.SDK.find_type_definition("via.movie.Movie");
local get_DurationTime_method = viaMovie_type_def:get_method("get_DurationTime"); -- retval, float
local seek_method = viaMovie_type_def:get_method("seek(System.UInt64)");

local notifyActionEnd_method = Constants.SDK.find_type_definition("via.behaviortree.ActionArg"):get_method("notifyActionEnd");
--
local isReLogo = nil;
local Movie = nil;
local function PreHook_play(args)
    if isReLogo then
        isReLogo = nil;
        Movie = Constants.SDK.to_managed_object(args[2]);
    end
end
local function PostHook_play()
    if Movie then
		local DurationTime = get_DurationTime_method:call(Movie);
		if DurationTime ~= nil then
			seek_method:call(Movie, DurationTime);
		end
	end
	Movie = nil;
end

local function ClearAction(args)
    local Action = Constants.SDK.to_managed_object(args[3]);
    if Action then
        notifyActionEnd_method:call(Action);
    end
end

local function ReLogo_ClearAction(args)
    isReLogo = true;
    ClearAction(args);
end

local function PreHook_OtherLogoFadeIn(args)
	local OtherLogoFadeIn = Constants.SDK.to_managed_object(args[2]);
	if OtherLogoFadeIn then
		Constants.SDK.hook_vtable(OtherLogoFadeIn, OtherLogoFadeIn:get_type_definition():get_method("update(via.behaviortree.ActionArg)"), ClearAction, Constants.ClearFade);
	end
end

local function PreHook_getTitlePressAnyButton()
	return Constants.SDK.SKIP_ORIGINAL;
end
local function PostHook_getTitlePressAnyButton()
    return Constants.TRUE_POINTER;
end

Constants.SDK.hook(viaMovie_type_def:get_method("play"), PreHook_play, PostHook_play);
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_CautionFadeIn"):get_method("start(via.behaviortree.ActionArg)"), nil, Constants.ClearFade);
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_CAPCOMLogoFadeIn"):get_method("start(via.behaviortree.ActionArg)"), nil, Constants.ClearFade);
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_RELogoFadeIn"):get_method("start(via.behaviortree.ActionArg)"), ReLogo_ClearAction, Constants.ClearFade);
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_OtherLogoFadeIn"):get_method("start(via.behaviortree.ActionArg)"), PreHook_OtherLogoFadeIn);
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_AutoSaveCaution_Action"):get_method("start(via.behaviortree.ActionArg)"), ClearAction);
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_HealthCautionFadeIn"):get_method("start(via.behaviortree.ActionArg)"), nil, Constants.ClearFade);
Constants.SDK.hook(Constants.type_definitions.StmGuiInput_type_def:get_method("getTitlePressAnyButton"), PreHook_getTitlePressAnyButton, PostHook_getTitlePressAnyButton);