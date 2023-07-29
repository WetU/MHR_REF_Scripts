local Constants = require("Constants.Constants");
--
sdk.hook(Constants.type_definitions.StmGuiInput_type_def:get_method("getTitlePressAnyButton"), Constants.SKIP_ORIGINAL, Constants.RETURN_TRUE);

if Constants.type_definitions.Application_type_def:get_method("get_UpTimeSecond"):call(nil) >= 120.0 then
	return;
end
--
local Movie_type_def = sdk.find_type_definition("via.movie.Movie");
local seek_method = Movie_type_def:get_method("seek(System.UInt64)");
local get_DurationTime_method = Movie_type_def:get_method("get_DurationTime");

local get_GameStartState_method = sdk.find_type_definition("snow.gui.fsm.title.GuiGameStartFsmManager"):get_method("get_GameStartState");

local notifyActionEnd_method = sdk.find_type_definition("via.behaviortree.ActionArg"):get_method("notifyActionEnd");
--
local Movie = nil;
local function PreHook_play(args)
	local GuiGameStartFsmManager = sdk.get_managed_singleton("snow.gui.fsm.title.GuiGameStartFsmManager");
	if GuiGameStartFsmManager == nil then
		return;
	end

	local GameStartState = get_GameStartState_method:call(sdk.get_managed_singleton("snow.gui.fsm.title.GuiGameStartFsmManager"));
	if GameStartState == nil or GameStartState < 0 or GameStartState > 7 then
		return;
	end

	Movie = sdk.to_managed_object(args[2]);
end
local function PostHook_play()
	if Movie == nil then
		return;
	end

	seek_method:call(Movie, get_DurationTime_method:call(Movie));
	Movie = nil;
end
--
local function ClearAction(args)
	notifyActionEnd_method:call(sdk.to_managed_object(args[3]));
end

local function Create_hook_vtable(args)
	local obj = sdk.to_managed_object(args[2]);
	sdk.hook_vtable(obj, obj:get_type_definition():get_method("update(via.behaviortree.ActionArg)"), ClearAction, Constants.ClearFade);
end

sdk.hook(Movie_type_def:get_method("play"), PreHook_play, PostHook_play);
sdk.hook(sdk.find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_CautionFadeIn"):get_method("update(via.behaviortree.ActionArg)"), Constants.ClearFade);
sdk.hook(sdk.find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_CAPCOMLogoFadeIn"):get_method("update(via.behaviortree.ActionArg)"), Constants.ClearFade);
sdk.hook(sdk.find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_RELogoFadeIn"):get_method("update(via.behaviortree.ActionArg)"), ClearAction, Constants.ClearFade);
sdk.hook(sdk.find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_OtherLogoFadeIn"):get_method("start(via.behaviortree.ActionArg)"), Create_hook_vtable);
sdk.hook(sdk.find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_AutoSaveCaution_Action"):get_method("update(via.behaviortree.ActionArg)"), ClearAction);
sdk.hook(sdk.find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_HealthCautionFadeIn"):get_method("start(via.behaviortree.ActionArg)"), Create_hook_vtable);