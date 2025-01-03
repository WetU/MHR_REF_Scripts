local Constants = _G.require("Constants.Constants");

local sdk = Constants.sdk;
local type_definitions = Constants.type_definitions;
local RETURN_TRUE_func = Constants.RETURN_TRUE_func;

local hook = sdk.hook;

local StmGuiInput_type_def = type_definitions.StmGuiInput_type_def;
--
if type_definitions.Application_type_def:get_method("get_UpTimeSecond"):call(nil) < 35.0 then
	local get_hook_storage = Constants.get_hook_storage;
	local find_type_definition = sdk.find_type_definition;
	local get_managed_singleton = sdk.get_managed_singleton;
	local to_managed_object = sdk.to_managed_object;
	local hook_vtable = sdk.hook_vtable;
	local ClearFade = Constants.ClearFade;
	--
	local Movie_type_def = find_type_definition("via.movie.Movie");
	local seek_method = Movie_type_def:get_method("seek(System.UInt64)");
	local get_DurationTime_method = Movie_type_def:get_method("get_DurationTime");
	--
	local get_GameStartState_method = find_type_definition("snow.gui.fsm.title.GuiGameStartFsmManager"):get_method("get_GameStartState");
	--
	local notifyActionEnd_method = find_type_definition("via.behaviortree.ActionArg"):get_method("notifyActionEnd");
	--
	local function PreHook_play(args)
		local GuiGameStartFsmManager = get_managed_singleton("snow.gui.fsm.title.GuiGameStartFsmManager");
		if GuiGameStartFsmManager ~= nil then
			local GameStartState = get_GameStartState_method:call(GuiGameStartFsmManager);
			if GameStartState ~= nil and GameStartState >= 0 and GameStartState <= 7 then
				get_hook_storage()["this"] = to_managed_object(args[1]);
			end
		end
	end
	local function PostHook_play()
		local Movie = get_hook_storage()["this"];
		if Movie ~= nil then
			seek_method:call(Movie, get_DurationTime_method:call(Movie));
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
	--
	hook(StmGuiInput_type_def:get_method("getTitleDispSkipTrg"), nil, RETURN_TRUE_func);
	hook(Movie_type_def:get_method("play"), PreHook_play, PostHook_play);
	hook(find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_CautionFadeIn"):get_method("update(via.behaviortree.ActionArg)"), ClearFade);
	hook(find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_CAPCOMLogoFadeIn"):get_method("update(via.behaviortree.ActionArg)"), ClearFade);
	hook(find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_RELogoFadeIn"):get_method("update(via.behaviortree.ActionArg)"), ClearAction, ClearFade);
	hook(find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_OtherLogoFadeIn"):get_method("start(via.behaviortree.ActionArg)"), Create_hook_vtable);
	hook(find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_AutoSaveCaution_Action"):get_method("update(via.behaviortree.ActionArg)"), ClearAction);
	hook(find_type_definition("snow.gui.fsm.title.GuiGameStartFsm_HealthCautionFadeIn"):get_method("start(via.behaviortree.ActionArg)"), Create_hook_vtable);
end

hook(StmGuiInput_type_def:get_method("getTitlePressAnyButton"), nil, RETURN_TRUE_func);