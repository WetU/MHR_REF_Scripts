local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
local sdk_to_managed_object = sdk.to_managed_object;
local sdk_to_ptr = sdk.to_ptr;
local sdk_hook = sdk.hook;
local sdk_hook_vtable = sdk.hook_vtable;
--
local Movie_type_def = sdk_find_type_definition("via.movie.Movie");
local play_method = Movie_type_def:get_method("play");
local get_DurationTime_method = Movie_type_def:get_method("get_DurationTime");
local seek_method = Movie_type_def:get_method("seek(System.UInt64)");

local notifyActionEnd_method = sdk_find_type_definition("via.behaviortree.ActionArg"):get_method("notifyActionEnd");
local set_FadeMode_method = sdk_find_type_definition("snow.FadeManager"):get_method("set_FadeMode(snow.FadeManager.MODE)");
local get_GameStartState_method = sdk_find_type_definition("snow.gui.fsm.title.GuiGameStartFsmManager"):get_method("get_GameStartState");
-- hook method --
local healthCautionFadeIn_start_method = sdk_find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_HealthCautionFadeIn"):get_method("start(via.behaviortree.ActionArg)");
local otherLogoFadeIn_start_method = sdk_find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_OtherLogoFadeIn"):get_method("start(via.behaviortree.ActionArg)");

local cautionFadeIn_update_method = sdk_find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_CautionFadeIn"):get_method("update(via.behaviortree.ActionArg)");
local capcomLogoFadeIn_update_method = sdk_find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_CAPCOMLogoFadeIn"):get_method("update(via.behaviortree.ActionArg)");
local reLogoFadeIn_update_method = sdk_find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_RELogoFadeIn"):get_method("update(via.behaviortree.ActionArg)");

local autoSaveCaution_Action_start_method = sdk_find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_AutoSaveCaution_Action"):get_method("start(via.behaviortree.ActionArg)");
local pressAnyButton_Action_start_method = sdk_find_type_definition("snow.gui.fsm.title.GuiTitleFsm_PressAnyButton_Action"):get_method("start(via.behaviortree.ActionArg)");

local getTitleDispSkipTrg_method = sdk_find_type_definition("snow.gui.StmGuiInput"):get_method("getTitleDispSkipTrg");
-- static --
local GameStartStateType_type_def = get_GameStartState_method:get_return_type();
local LOADING_STATES =	{
	[GameStartStateType_type_def:get_field("Caution"):get_data(nil)] = false, -- 0
	[GameStartStateType_type_def:get_field("CAPCOM_Logo"):get_data(nil)] = true, -- 1
	[GameStartStateType_type_def:get_field("Re_Logo"):get_data(nil)] = true, -- 2
	[GameStartStateType_type_def:get_field("SpeedTree_Logo"):get_data(nil)] = false, -- 3
	[GameStartStateType_type_def:get_field("AutoSave_Caution"):get_data(nil)] = false, -- 4
	[GameStartStateType_type_def:get_field("Blank"):get_data(nil)] = true, -- 5
	[GameStartStateType_type_def:get_field("Health_Caution"):get_data(nil)] = true, -- 6
	[GameStartStateType_type_def:get_field("Nvidia_Logo"):get_data(nil)] = false -- 7
};

local FINISHED = sdk_find_type_definition("snow.FadeManager.MODE"):get_field("FINISH"):get_data(nil);
-- clear fadeout
local function ClearFade()
	local FadeManager = sdk_get_managed_singleton("snow.FadeManager");
	if FadeManager then
		set_FadeMode_method:call(FadeManager, FINISHED);
		FadeManager:set_field("fadeOutInFlag", false);
	end
end

sdk_hook(healthCautionFadeIn_start_method, function(args)
	local healthCautionFadeIn = sdk_to_managed_object(args[2]);
	if healthCautionFadeIn ~= nil then
		sdk_hook_vtable(healthCautionFadeIn, healthCautionFadeIn:get_type_definition():get_method("update(via.behaviortree.ActionArg)"), nil, ClearFade);
	end
end);
sdk_hook(cautionFadeIn_update_method, nil, ClearFade);
sdk_hook(capcomLogoFadeIn_update_method, nil, ClearFade);

-- Actual skip actions
local currentAction = nil;
local function PreHook_GetActionObject(args)
	currentAction = sdk_to_managed_object(args[3]);
end

local function PostHook_notifyActionEnd()
	if currentAction then
		notifyActionEnd_method:call(currentAction);
	end
	currentAction = nil;
end

sdk_hook(autoSaveCaution_Action_start_method, PreHook_GetActionObject, PostHook_notifyActionEnd);
sdk_hook(pressAnyButton_Action_start_method, PreHook_GetActionObject, PostHook_notifyActionEnd);

local function ClearFadeWithAction()
	PostHook_notifyActionEnd();
	ClearFade();
end

sdk_hook(otherLogoFadeIn_start_method, function(args)
	local otherLogoFadeIn = sdk_to_managed_object(args[2]);
	if otherLogoFadeIn ~= nil then
		sdk_hook_vtable(otherLogoFadeIn, otherLogoFadeIn:get_type_definition():get_method("update(via.behaviortree.ActionArg)"), PreHook_GetActionObject, ClearFadeWithAction);
	end
end);
sdk_hook(reLogoFadeIn_update_method, PreHook_GetActionObject, ClearFadeWithAction);

-- Fast forward movies to the end to mute audio
local function isLoading()
	local GuiGameStartFsmManager = sdk_get_managed_singleton("snow.gui.fsm.title.GuiGameStartFsmManager");
	if GuiGameStartFsmManager then
		return LOADING_STATES[get_GameStartState_method:call(GuiGameStartFsmManager)];
	end
	return false;
end

local currentMovie = nil;
sdk_hook(play_method, function(args)
	if isLoading() then
		currentMovie = sdk_to_managed_object(args[2]);
	end
end, function()
	if currentMovie then
		local DurationTime = get_DurationTime_method:call(currentMovie);
		if DurationTime ~= nil then
			seek_method:call(currentMovie, DurationTime);
		end
	end
	currentMovie = nil;
end);

-- Fake title skip input for HEALTH/Capcom
local SkipTrg = sdk_to_ptr(1);
sdk_hook(getTitleDispSkipTrg_method, nil, function()
	if isLoading() then
		return SkipTrg;
	end
end);