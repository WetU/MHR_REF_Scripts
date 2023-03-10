local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
local sdk_to_managed_object = sdk.to_managed_object;
local sdk_to_ptr = sdk.to_ptr;
local sdk_CALL_ORIGINAL = sdk.PreHookResult.CALL_ORIGINAL;
local sdk_hook = sdk.hook;

local Movie_type_def = sdk_find_type_definition("via.movie.Movie");
local play_method = Movie_type_def:get_method("play");
local get_DurationTime_method = Movie_type_def:get_method("get_DurationTime");
local seek_method = Movie_type_def:get_method("seek(System.UInt64)");
-- hook method --
local cautionFadeIn_Update_method = sdk_find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_CautionFadeIn"):get_method("update(via.behaviortree.ActionArg)");
local capcomLogoFadeIn_Update_method = sdk_find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_CAPCOMLogoFadeIn"):get_method("update(via.behaviortree.ActionArg)");
local healthCautionFadeIn_Update_method = sdk_find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_HealthCautionFadeIn"):get_method("update(via.behaviortree.ActionArg)");
local reLogoFadeIn_Update_method = sdk_find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_RELogoFadeIn"):get_method("update(via.behaviortree.ActionArg)");
local otherLogoFadeIn_Update_method = sdk_find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_OtherLogoFadeIn"):get_method("update(via.behaviortree.ActionArg)");
local autoSaveCaution_Action_Start_method = sdk_find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_AutoSaveCaution_Action"):get_method("start(via.behaviortree.ActionArg)");
local pressAnyButton_Action_start_method = sdk_find_type_definition("snow.gui.fsm.title.GuiTitleFsm_PressAnyButton_Action"):get_method("start(via.behaviortree.ActionArg)");
local getTitleDispSkipTrg_method = sdk_find_type_definition("snow.gui.StmGuiInput"):get_method("getTitleDispSkipTrg");
----------------
local get_GameStartState_method = sdk_find_type_definition("snow.gui.fsm.title.GuiGameStartFsmManager"):get_method("get_GameStartState");

local notifyActionEnd_method = sdk_find_type_definition("via.behaviortree.ActionArg"):get_method("notifyActionEnd");

local set_FadeMode_method = sdk_find_type_definition("snow.FadeManager"):get_method("set_FadeMode(snow.FadeManager.MODE)");
-- static --
local GameStartStateType_type_def = sdk_find_type_definition("snow.gui.fsm.title.GuiGameStartFsmManager.GameStartStateType");
local LOADING_STATES =
	{
		[GameStartStateType_type_def:get_field("CAPCOM_Logo"):get_data(nil)] = true, -- 1
		[GameStartStateType_type_def:get_field("Re_Logo"):get_data(nil)] = true, -- 2
		[GameStartStateType_type_def:get_field("Blank"):get_data(nil)] = true, -- 5
		[GameStartStateType_type_def:get_field("Health_Caution"):get_data(nil)] = true -- 6
	};
local FINISHED = sdk_find_type_definition("snow.FadeManager.MODE"):get_field("FINISH"):get_data(nil);
------------
local function isLoading()
	local GuiGameStartFsmManager = sdk_get_managed_singleton("snow.gui.fsm.title.GuiGameStartFsmManager");
	if GuiGameStartFsmManager then
		return LOADING_STATES[get_GameStartState_method:call(GuiGameStartFsmManager)];
	end
	return false;
end

local function skipAction(action)
	if action then
		notifyActionEnd_method:call(action);
	end
end

local function ClearFade_main()
	local FadeManager = sdk_get_managed_singleton("snow.FadeManager");
	if FadeManager then
		set_FadeMode_method:call(FadeManager, FINISHED);
		FadeManager:set_field("fadeOutInFlag", false);
	end
end

local function ClearFade()
	ClearFade_main();
	return sdk_CALL_ORIGINAL;
end

local function ClearFadeWithAction(args)
	local ActionArg = sdk_to_managed_object(args[3]);
	if ActionArg then
		skipAction(ActionArg);
	end
	ClearFade_main();
	return sdk_CALL_ORIGINAL;
end

-- Fast forward movies to the end to mute audio
local currentMovie = nil;
sdk_hook(play_method, function(args)
	currentMovie = sdk_to_managed_object(args[2]);
	return sdk_CALL_ORIGINAL;
end, function(ret)
	if isLoading() and currentMovie then
		local DurationTime = get_DurationTime_method:call(currentMovie);
		if DurationTime then
			seek_method:call(currentMovie, DurationTime);
		end
	end
	currentMovie = nil;
	return ret;
end);

-- clear fadeout
sdk_hook(cautionFadeIn_Update_method, ClearFade);
sdk_hook(capcomLogoFadeIn_Update_method, ClearFade);
sdk_hook(healthCautionFadeIn_Update_method, ClearFade);

-- Actual skip actions
sdk_hook(reLogoFadeIn_Update_method, ClearFadeWithAction);
sdk_hook(otherLogoFadeIn_Update_method, ClearFadeWithAction);

local currentAction = nil;
sdk_hook(autoSaveCaution_Action_Start_method, function(args)
	currentAction = sdk_to_managed_object(args[3]);
	return sdk_CALL_ORIGINAL;
end, function(ret) 
	skipAction(currentAction);
	currentAction = nil;
	return ret;
end);

sdk_hook(pressAnyButton_Action_start_method, function(args)
	currentAction = sdk_to_managed_object(args[3]);
	return sdk_CALL_ORIGINAL;
end, function(ret)
	skipAction(currentAction);
	currentAction = nil;
	return ret;
end);

-- Fake title skip input for HEALTH/Capcom
sdk_hook(getTitleDispSkipTrg_method, nil, function(retval)
	if isLoading() then
		return sdk_to_ptr(1);
	end
	return retval;
end);