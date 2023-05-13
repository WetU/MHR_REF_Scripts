local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
local sdk_to_managed_object = sdk.to_managed_object;
local sdk_call_native_func = sdk.call_native_func;
local sdk_to_ptr = sdk.to_ptr;
local sdk_hook = sdk.hook;
local sdk_hook_vtable = sdk.hook_vtable;
--
local ActionArg_type_def = sdk_find_type_definition("via.behaviortree.ActionArg");
local Movie_type_def = sdk_find_type_definition("via.movie.Movie");
local play_method = Movie_type_def:get_method("play"); -- native
local set_FadeMode_method = sdk_find_type_definition("snow.FadeManager"):get_method("set_FadeMode(snow.FadeManager.MODE)");
local get_GameStartState_method = sdk_find_type_definition("snow.gui.fsm.title.GuiGameStartFsmManager"):get_method("get_GameStartState"); -- retval
-- hook method --
local cautionFadeIn_update_method = sdk_find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_CautionFadeIn"):get_method("update(via.behaviortree.ActionArg)");
local capcomLogoFadeIn_update_method = sdk_find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_CAPCOMLogoFadeIn"):get_method("update(via.behaviortree.ActionArg)");
local reLogoFadeIn_update_method = sdk_find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_RELogoFadeIn"):get_method("update(via.behaviortree.ActionArg)");
local otherLogoFadeIn_start_method = sdk_find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_OtherLogoFadeIn"):get_method("start(via.behaviortree.ActionArg)");
local autoSaveCaution_Action_start_method = sdk_find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_AutoSaveCaution_Action"):get_method("start(via.behaviortree.ActionArg)");
local getTitlePressAnyButton_method = sdk_find_type_definition("snow.gui.StmGuiInput"):get_method("getTitlePressAnyButton"); -- static, retval
local healthCautionFadeIn_start_method = sdk_find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_HealthCautionFadeIn"):get_method("start(via.behaviortree.ActionArg)");
-- static --
local FINISHED = sdk_find_type_definition("snow.FadeManager.MODE"):get_field("FINISH"):get_data(nil);
local GameStartStateType_type_def = get_GameStartState_method:get_return_type();
local LOADING_STATES =	{
	Caution = GameStartStateType_type_def:get_field("Caution"):get_data(nil), -- 0
	CAPCOM_Logo = GameStartStateType_type_def:get_field("CAPCOM_Logo"):get_data(nil), -- 1
	Re_Logo = GameStartStateType_type_def:get_field("Re_Logo"):get_data(nil), -- 2
	SpeedTree_Logo = GameStartStateType_type_def:get_field("SpeedTree_Logo"):get_data(nil), -- 3
	AutoSave_Caution = GameStartStateType_type_def:get_field("AutoSave_Caution"):get_data(nil), -- 4
	Blank = GameStartStateType_type_def:get_field("Blank"):get_data(nil), -- 5
	Health_Caution = GameStartStateType_type_def:get_field("Health_Caution"):get_data(nil), -- 6
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
		return GameStartState ~= nil and (GameStartState >= LOADING_STATES.Caution and GameStartState <= LOADING_STATES.Nvidia_Logo) or GameStartState;
	end
	return false;
end

local SkipTrg = sdk_to_ptr(1);
--
local currentMovie = nil;
local otherLogoFadeIn = nil;
local healthCautionFadeIn = nil
sdk_hook(play_method, function(args)
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

sdk_hook(cautionFadeIn_update_method, nil, ClearFade);
sdk_hook(capcomLogoFadeIn_update_method, nil, ClearFade);
sdk_hook(reLogoFadeIn_update_method, PreHook_GetActionObject, ClearFadeWithAction);
sdk_hook(otherLogoFadeIn_start_method, function(args)
	otherLogoFadeIn = sdk_to_managed_object(args[2]);
end, function()
	if otherLogoFadeIn then
		sdk_hook_vtable(otherLogoFadeIn, otherLogoFadeIn:get_type_definition():get_method("update(via.behaviortree.ActionArg)"), PreHook_GetActionObject, ClearFadeWithAction);
	end
	otherLogoFadeIn = nil;
end);
sdk_hook(autoSaveCaution_Action_start_method, PreHook_GetActionObject, PostHook_notifyActionEnd);
sdk_hook(healthCautionFadeIn_start_method, function(args)
	healthCautionFadeIn = sdk_to_managed_object(args[2]);
end, function()
	if healthCautionFadeIn then
		sdk_hook_vtable(healthCautionFadeIn, healthCautionFadeIn:get_type_definition():get_method("update(via.behaviortree.ActionArg)"), nil, ClearFade);
	end
	healthCautionFadeIn = nil;
end);
sdk_hook(getTitlePressAnyButton_method, nil, function(retval)
	if isLoading() then
		return SkipTrg;
	end
	return retval;
end);