local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
local sdk_to_managed_object = sdk.to_managed_object;
local sdk_call_native_func = sdk.call_native_func;
local sdk_hook = sdk.hook;
local sdk_hook_vtable = sdk.hook_vtable;
--
local ActionArg_type_def = sdk_find_type_definition("via.behaviortree.ActionArg");
local Movie_type_def = sdk_find_type_definition("via.movie.Movie");
local set_FadeMode_method = sdk_find_type_definition("snow.FadeManager"):get_method("set_FadeMode(snow.FadeManager.MODE)");
local get_GameStartState_method = sdk_find_type_definition("snow.gui.fsm.title.GuiGameStartFsmManager"):get_method("get_GameStartState"); -- retval
-- static --
local FINISHED = sdk_find_type_definition("snow.FadeManager.MODE"):get_field("FINISH"):get_data(nil);
local GameStartStateType_type_def = get_GameStartState_method:get_return_type();
local LOADING_STATES =	{
	Caution = GameStartStateType_type_def:get_field("Caution"):get_data(nil), -- 0
	Nvidia_Logo = GameStartStateType_type_def:get_field("Nvidia_Logo"):get_data(nil) -- 7
};
--
local function ClearFade()
	local FadeManager = sdk_get_managed_singleton("snow.FadeManager");
	if FadeManager then
		set_FadeMode_method:call(FadeManager, FINISHED);
		FadeManager:set_field("fadeOutInFlag", false);
	end
end

local currentAction = nil;
local function PreHook_GetActionObject(args)
	currentAction = sdk_to_managed_object(args[3]);
end

local function PostHook_notifyActionEnd()
	if currentAction then
		sdk_call_native_func(currentAction, ActionArg_type_def, "notifyActionEnd");
	end
	currentAction = nil;
end

local function ClearFadeWithAction()
	PostHook_notifyActionEnd();
	ClearFade();
end

local function isLoading()
	local GuiGameStartFsmManager = sdk_get_managed_singleton("snow.gui.fsm.title.GuiGameStartFsmManager");
	if GuiGameStartFsmManager then
		local GameStartState = get_GameStartState_method:call(GuiGameStartFsmManager);
		return GameStartState ~= nil and (GameStartState >= LOADING_STATES.Caution and GameStartState <= LOADING_STATES.Nvidia_Logo) or nil;
	end
	return false;
end

local SkipTrg = sdk.to_ptr(1);
--
local currentMovie = nil;
local otherLogoFadeIn = nil;
local healthCautionFadeIn = nil;
sdk_hook(Movie_type_def:get_method("play"), function(args)
	if isLoading() then
		currentMovie = sdk_to_managed_object(args[2]);
	end
end, function()
	if currentMovie then
		local DurationTime = sdk_call_native_func(currentMovie, Movie_type_def, "get_DurationTime");
		if DurationTime ~= nil then
			sdk_call_native_func(currentMovie, Movie_type_def, "seek(System.UInt64)", DurationTime);
		end
	end
	currentMovie = nil;
end);

sdk_hook(sdk_find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_CautionFadeIn"):get_method("update(via.behaviortree.ActionArg)"), nil, ClearFade);
sdk_hook(sdk_find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_CAPCOMLogoFadeIn"):get_method("update(via.behaviortree.ActionArg)"), nil, ClearFade);
sdk_hook(sdk_find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_RELogoFadeIn"):get_method("update(via.behaviortree.ActionArg)"), PreHook_GetActionObject, ClearFadeWithAction);
sdk_hook(sdk_find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_OtherLogoFadeIn"):get_method("start(via.behaviortree.ActionArg)"), function(args)
	otherLogoFadeIn = sdk_to_managed_object(args[2]);
end, function()
	if otherLogoFadeIn then
		sdk_hook_vtable(otherLogoFadeIn, otherLogoFadeIn:get_type_definition():get_method("update(via.behaviortree.ActionArg)"), PreHook_GetActionObject, ClearFadeWithAction);
	end
	otherLogoFadeIn = nil;
end);
sdk_hook(sdk_find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_AutoSaveCaution_Action"):get_method("start(via.behaviortree.ActionArg)"), PreHook_GetActionObject, PostHook_notifyActionEnd);
sdk_hook(sdk_find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_HealthCautionFadeIn"):get_method("start(via.behaviortree.ActionArg)"), function(args)
	healthCautionFadeIn = sdk_to_managed_object(args[2]);
end, function()
	if healthCautionFadeIn then
		sdk_hook_vtable(healthCautionFadeIn, healthCautionFadeIn:get_type_definition():get_method("update(via.behaviortree.ActionArg)"), nil, ClearFade);
	end
	healthCautionFadeIn = nil;
end);
sdk_hook(sdk_find_type_definition("snow.gui.StmGuiInput"):get_method("getTitlePressAnyButton"), nil, function(retval)
	if isLoading() then
		return SkipTrg;
	end
	return retval;
end);