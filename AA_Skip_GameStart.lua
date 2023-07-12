local Constants = require("Constants.Constants");
if not Constants then
	return;
end
--
local Movie_type_def = Constants.SDK.find_type_definition("via.movie.Movie");
local seek_method = Movie_type_def:get_method("seek(System.UInt64)");
local get_DurationTime_method = Movie_type_def:get_method("get_DurationTime");

local get_GameStartState_method = Constants.SDK.find_type_definition("snow.gui.fsm.title.GuiGameStartFsmManager"):get_method("get_GameStartState");

local notifyActionEnd_method = Constants.SDK.find_type_definition("via.behaviortree.ActionArg"):get_method("notifyActionEnd");
--
local Movie = nil;
local function PreHook_play(args)
	local GuiGameStartFsmManager = Constants.SDK.get_managed_singleton("snow.gui.fsm.title.GuiGameStartFsmManager");
	if GuiGameStartFsmManager == nil then
		return;
	end

	local GameStartState = get_GameStartState_method:call(GuiGameStartFsmManager);
	if GameStartState == nil or GameStartState < 0 or GameStartState > 7 then
		return;
	end

	Movie = Constants.SDK.to_managed_object(args[2]);
end
local function PostHook_play()
	if Movie == nil then
		return;
	end

	local DurationTime = get_DurationTime_method:call(Movie);
	if DurationTime ~= nil then
		seek_method:call(Movie, DurationTime);
	end

	Movie = nil;
end

local function ClearAction(args)
	local Action = Constants.SDK.to_managed_object(args[3]);
	if Action == nil then
		return;
	end

	notifyActionEnd_method:call(Action);
end

local function Create_hook_vtable(args)
	local obj = Constants.SDK.to_managed_object(args[2]);
	if obj == nil then
		return;
	end

	Constants.SDK.hook_vtable(obj, obj:get_type_definition():get_method("update(via.behaviortree.ActionArg)"), ClearAction, Constants.ClearFade);
end

Constants.SDK.hook(Movie_type_def:get_method("play"), PreHook_play, PostHook_play);
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_CautionFadeIn"):get_method("update(via.behaviortree.ActionArg)"), Constants.ClearFade);
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_CAPCOMLogoFadeIn"):get_method("update(via.behaviortree.ActionArg)"), Constants.ClearFade);
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_RELogoFadeIn"):get_method("update(via.behaviortree.ActionArg)"), ClearAction, Constants.ClearFade);
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_OtherLogoFadeIn"):get_method("start(via.behaviortree.ActionArg)"), Create_hook_vtable);
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_AutoSaveCaution_Action"):get_method("update(via.behaviortree.ActionArg)"), ClearAction);
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_HealthCautionFadeIn"):get_method("start(via.behaviortree.ActionArg)"), Create_hook_vtable);
Constants.SDK.hook(Constants.type_definitions.StmGuiInput_type_def:get_method("getTitlePressAnyButton"), Constants.SKIP_ORIGINAL, Constants.Return_TRUE);