local Constants = require("Constants.Constants");
if not Constants then
	return;
end
--
local config = Constants.JSON.load_file("RiseTweaks/config.json") or {enableFPS = true, autoFPS = true, desiredFPS = 60.0};
if config.enableFPS == nil then
	config.enableFPS = true;
end
if config.autoFPS == nil then
	config.autoFPS = true;
end
if config.desiredFPS == nil then
	config.desiredFPS = 60.0;
end
--
local Application_type_def = Constants.SDK.find_type_definition("via.Application");
local ActionArg_type_def = Constants.SDK.find_type_definition("via.behaviortree.ActionArg");
local viaMovie_type_def = Constants.SDK.find_type_definition("via.movie.Movie");

local get_GameStartState_method = Constants.SDK.find_type_definition("snow.gui.fsm.title.GuiGameStartFsmManager"):get_method("get_GameStartState"); -- retval
local set_FadeMode_method = Constants.SDK.find_type_definition("snow.FadeManager"):get_method("set_FadeMode(snow.FadeManager.MODE)");

local StmOptionDataContainer_field = Constants.SDK.find_type_definition("snow.StmOptionManager"):get_field("_StmOptionDataContainer");
local getFrameRateOption_method = StmOptionDataContainer_field:get_type():get_method("getFrameRateOption"); -- retval
local FrameRateOption_type_def = getFrameRateOption_method:get_return_type();
local FrameRate = {
	[FrameRateOption_type_def:get_field("FPS_30"):get_data(nil)] = 30.0,
	[FrameRateOption_type_def:get_field("FPS_60"):get_data(nil)] = 60.0,
	[FrameRateOption_type_def:get_field("FPS_90"):get_data(nil)] = 90.0,
	[FrameRateOption_type_def:get_field("FPS_120"):get_data(nil)] = 120.0,
	[FrameRateOption_type_def:get_field("FPS_144"):get_data(nil)] = 144.0,
	[FrameRateOption_type_def:get_field("FPS_165"):get_data(nil)] = 165.0,
	[FrameRateOption_type_def:get_field("FPS_240"):get_data(nil)] = 240.0,
	[FrameRateOption_type_def:get_field("FPS_Unlimited"):get_data(nil)] = 600.0
};

local FINISHED = Constants.SDK.find_type_definition("snow.FadeManager.MODE"):get_field("FINISH"):get_data(nil);

local GameStartStateType_type_def = get_GameStartState_method:get_return_type();
local GAME_START_STATES =	{
	Caution = GameStartStateType_type_def:get_field("Caution"):get_data(nil), -- 0
	Nvidia_Logo = GameStartStateType_type_def:get_field("Nvidia_Logo"):get_data(nil) -- 7
};
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
		Constants.SDK.call_native_func(currentAction, ActionArg_type_def, "notifyActionEnd");
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

local function IsGameStartState()
	local GuiGameStartFsmManager = Constants.SDK.get_managed_singleton("snow.gui.fsm.title.GuiGameStartFsmManager");
	if GuiGameStartFsmManager then
		local GameStartState = get_GameStartState_method:call(GuiGameStartFsmManager);
		if GameStartState ~= nil and (GameStartState >= GAME_START_STATES.Caution and GameStartState <= GAME_START_STATES.Nvidia_Logo) then
			return true;
		end
	end
	return false;
end

local function TitleSkip(retval)
	if IsGameStartState() then
		return Constants.TRUE_POINTER;
	end
	return retval;
end

local function getAutoFps()
	local OptionManager = Constants.SDK.get_managed_singleton("snow.StmOptionManager");
	if OptionManager then
		local OptionDataContainer = StmOptionDataContainer_field:get_data(OptionManager);
		if OptionDataContainer then
			local FrameRateOption = getFrameRateOption_method:call(OptionDataContainer);
			if FrameRateOption then
				config.desiredFPS = FrameRate[FrameRateOption];
			end
		end
	end
end

local function applyFps()
	if config.autoFPS then
		getAutoFps();
	end
	Constants.SDK.call_native_func(Constants.SDK.get_native_singleton("via.Application"), Application_type_def, "set_MaxFps(System.Single)", config.desiredFPS);
end
--
local firstHook = true;
local currentMovie = nil;
Constants.SDK.hook(viaMovie_type_def:get_method("play"), function(args)
	if IsGameStartState() then
		currentMovie = Constants.SDK.to_managed_object(args[2]);
	end
end, function()
	if currentMovie then
		local DurationTime = Constants.SDK.call_native_func(currentMovie, viaMovie_type_def, "get_DurationTime");
		if DurationTime ~= nil then
			Constants.SDK.call_native_func(currentMovie, viaMovie_type_def, "seek(System.UInt64)", DurationTime);
		end
		if firstHook then
			firstHook = nil;
			applyFps();
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

Constants.SDK.hook(Constants.type_definitions.StmGuiInput_type_def:get_method("getTitlePressAnyButton"), nil, TitleSkip);
Constants.SDK.hook(Constants.type_definitions.StmGuiInput_type_def:get_method("getTitleDispSkipTrg"), nil, TitleSkip);

Constants.SDK.hook(Constants.SDK.find_type_definition("snow.eventcut.UniqueEventManager"):get_method("playEventCommon(System.Boolean, System.Int32)"), nil, function()
	if config.enableFPS then
		applyFps();
	end
end);
--
local function save_config()
	Constants.JSON.dump_file("RiseTweaks/config.json", config);
end

Constants.RE.on_config_save(save_config);

Constants.RE.on_draw_ui(function()
	local changed = false;
	if Constants.IMGUI.tree_node("RiseTweaks") then
		if Constants.IMGUI.tree_node("Frame Rate") then
			changed, config.enableFPS = Constants.IMGUI.checkbox("Enable", config.enableFPS);
			if config.enableFPS then
				changed, config.autoFPS = Constants.IMGUI.checkbox("Automatic Frame Rate", config.autoFPS);
				if not config.autoFPS then
					changed, config.desiredFPS = Constants.IMGUI.slider_float("Frame Rate", config.desiredFPS, 10.0, 600.0, "%.2f");
				end
			end
			if changed then
				if config.enableFPS then
					applyFps();
				end
				save_config();
			end
			Constants.IMGUI.tree_pop();
		end
	end
end);