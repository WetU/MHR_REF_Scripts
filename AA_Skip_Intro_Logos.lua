local Constants = require("Constants.Constants");
if not Constants then
	return;
end
--
local set_FadeMode_method = Constants.SDK.find_type_definition("snow.FadeManager"):get_method("set_FadeMode(snow.FadeManager.MODE)");
--
local FINISHED = Constants.SDK.find_type_definition("snow.FadeManager.MODE"):get_field("FINISH"):get_data(nil);
--
local function ClearFade()
	local FadeManager = Constants.SDK.get_managed_singleton("snow.FadeManager");
	if FadeManager then
		set_FadeMode_method:call(FadeManager, FINISHED);
		FadeManager:set_field("fadeOutInFlag", false);
	end
end

local currentAction = nil;
local function PreHook_GetActionObject(args)
	currentAction = Constants.SDK.to_managed_object(args[3]);
end

local function PostHook_notifyActionEnd()
	if currentAction then
		Constants.SDK.call_native_func(currentAction, currentAction:get_type_definition(), "notifyActionEnd");
	end
	currentAction = nil;
end

local selfObj = nil;
local function PreHook_GetSelfObject(args)
	selfObj = Constants.SDK.to_managed_object(args[2]);
end

local function ClearFadeWithAction()
	PostHook_notifyActionEnd();
	ClearFade();
end

local function TitleSkip(retval)
	if Constants.IsGameStartState() then
		return Constants.TRUE_POINTER;
	end
	return retval;
end
--
local currentMovie = nil;
Constants.SDK.hook(Constants.SDK.find_type_definition("via.movie.Movie"):get_method("play"), function(args)
	if Constants.IsGameStartState() then
		currentMovie = Constants.SDK.to_managed_object(args[2]);
	end
end, function()
	if currentMovie then
		local currentMovie_type_def = currentMovie:get_type_definition();
		if currentMovie_type_def then
			local DurationTime = Constants.SDK.call_native_func(currentMovie, currentMovie_type_def, "get_DurationTime");
			if DurationTime ~= nil then
				Constants.SDK.call_native_func(currentMovie, currentMovie_type_def, "seek(System.UInt64)", DurationTime);
			end
		end
	end
	currentMovie = nil;
end);
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_CautionFadeIn"):get_method("update(via.behaviortree.ActionArg)"), nil, ClearFade);
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_CAPCOMLogoFadeIn"):get_method("update(via.behaviortree.ActionArg)"), nil, ClearFade);
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_RELogoFadeIn"):get_method("update(via.behaviortree.ActionArg)"), PreHook_GetActionObject, ClearFadeWithAction);
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_OtherLogoFadeIn"):get_method("start(via.behaviortree.ActionArg)"), PreHook_GetVTableObejct, function()
	if selfObj then
		Constants.SDK.hook_vtable(selfObj, selfObj:get_type_definition():get_method("update(via.behaviortree.ActionArg)"), PreHook_GetActionObject, ClearFadeWithAction);
	end
	selfObj = nil;
end);
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_AutoSaveCaution_Action"):get_method("start(via.behaviortree.ActionArg)"), PreHook_GetActionObject, PostHook_notifyActionEnd);
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_HealthCautionFadeIn"):get_method("start(via.behaviortree.ActionArg)"), PreHook_GetVTableObejct, function()
	if selfObj then
		Constants.SDK.hook_vtable(selfObj, selfObj:get_type_definition():get_method("update(via.behaviortree.ActionArg)"), nil, ClearFade);
	end
	selfObj = nil;
end);

local StmGuiInput_type_def = Constants.SDK.find_type_definition("snow.gui.StmGuiInput");
Constants.SDK.hook(StmGuiInput_type_def:get_method("getTitlePressAnyButton"), nil, TitleSkip);
Constants.SDK.hook(StmGuiInput_type_def:get_method("getTitleDispSkipTrg"), nil, TitleSkip);
