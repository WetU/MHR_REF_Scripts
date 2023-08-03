local require = require;
local Constants = require("Constants.Constants");

local find_type_definition = Constants.sdk.find_type_definition;
local get_managed_singleton = Constants.sdk.get_managed_singleton;
local to_managed_object = Constants.sdk.to_managed_object;
local hook = Constants.sdk.hook;
local hook_vtable = Constants.sdk.hook_vtable;

local RETURN_TRUE_func = Constants.RETURN_TRUE;
local ClearFade = Constants.ClearFade;
--
local type_definitions = Constants.type_definitions;
hook(type_definitions.StmGuiInput_type_def:get_method("getTitlePressAnyButton"), nil, RETURN_TRUE_func);

if type_definitions.Application_type_def:get_method("get_UpTimeSecond"):call(nil) < 120.0 then
	local Movie_type_def = find_type_definition("via.movie.Movie");
	local seek_method = Movie_type_def:get_method("seek(System.UInt64)");
	local get_DurationTime_method = Movie_type_def:get_method("get_DurationTime");

	local get_GameStartState_method = find_type_definition("snow.gui.fsm.title.GuiGameStartFsmManager"):get_method("get_GameStartState");

	local notifyActionEnd_method = find_type_definition("via.behaviortree.ActionArg"):get_method("notifyActionEnd");
	--
	local Movie = nil;
	local function PreHook_play(args)
		local GuiGameStartFsmManager = get_managed_singleton("snow.gui.fsm.title.GuiGameStartFsmManager");
		if GuiGameStartFsmManager ~= nil then
			local GameStartState = get_GameStartState_method:call(get_managed_singleton("snow.gui.fsm.title.GuiGameStartFsmManager"));
			if GameStartState ~= nil and GameStartState >= 0 and GameStartState <= 7 then
				Movie = to_managed_object(args[2]);
			end
		end
	end
	local function PostHook_play()
		if Movie ~= nil then
			seek_method:call(Movie, get_DurationTime_method:call(Movie));
			Movie = nil;
		end
	end
	--
	local function ClearAction(args)
		notifyActionEnd_method:call(to_managed_object(args[3]));
	end

	local function Create_hook_vtable(args)
		local obj = to_managed_object(args[2]);
		hook_vtable(obj, obj:get_type_definition():get_method("update(via.behaviortree.ActionArg)"), ClearAction, ClearFade);
	end

	hook(Movie_type_def:get_method("play"), PreHook_play, PostHook_play);
	hook(find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_CautionFadeIn"):get_method("update(via.behaviortree.ActionArg)"), ClearFade);
	hook(find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_CAPCOMLogoFadeIn"):get_method("update(via.behaviortree.ActionArg)"), ClearFade);
	hook(find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_RELogoFadeIn"):get_method("update(via.behaviortree.ActionArg)"), ClearAction, ClearFade);
	hook(find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_OtherLogoFadeIn"):get_method("start(via.behaviortree.ActionArg)"), Create_hook_vtable);
	hook(find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_AutoSaveCaution_Action"):get_method("update(via.behaviortree.ActionArg)"), ClearAction);
	hook(find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_HealthCautionFadeIn"):get_method("start(via.behaviortree.ActionArg)"), Create_hook_vtable);
end