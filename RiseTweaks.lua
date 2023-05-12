local json = json;
local json_load_file = json.load_file;
local json_dump_file = json.dump_file;

local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
local sdk_to_managed_object = sdk.to_managed_object;
local sdk_hook = sdk.hook;

local re = re;
local re_on_draw_ui = re.on_draw_ui;
local re_on_config_save = re.on_config_save;

local imgui = imgui;
local imgui_tree_node = imgui.tree_node;
local imgui_checkbox = imgui.checkbox;
local imgui_tree_pop = imgui.tree_pop;
local imgui_slider_float = imgui.slider_float;

local config = json_load_file("RiseTweaks/config.json") or {enableFPS = true, autoFPS = true, desiredFPS = 60.0};
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
local Movie_type_def = sdk_find_type_definition("via.movie.Movie");
local play_method = Movie_type_def:get_method("play"); -- native

local get_GameStartState_method = sdk_find_type_definition("snow.gui.fsm.title.GuiGameStartFsmManager"):get_method("get_GameStartState"); -- retval

local GameStartState_type_def = get_GameStartState_method:get_return_type();
local GameStartState =	{
	[GameStartState_type_def:get_field("Caution"):get_data(nil)] = true,
	[GameStartState_type_def:get_field("CAPCOM_Logo"):get_data(nil)] = true,
	[GameStartState_type_def:get_field("Re_Logo"):get_data(nil)] = true,
	[GameStartState_type_def:get_field("SpeedTree_Logo"):get_data(nil)] = true,
	[GameStartState_type_def:get_field("AutoSave_Caution"):get_data(nil)] = true,
	[GameStartState_type_def:get_field("Blank"):get_data(nil)] = true,
	[GameStartState_type_def:get_field("Health_Caution"):get_data(nil)] = true,
	[GameStartState_type_def:get_field("Nvidia_Logo"):get_data(nil)] = true
};

local StmOptionDataContainer_field = sdk_find_type_definition("snow.StmOptionManager"):get_field("_StmOptionDataContainer");

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

local playEventCommon_method = sdk_find_type_definition("snow.eventcut.UniqueEventManager"):get_method("playEventCommon(System.Boolean, System.Int32)");
local set_MaxFps_method = sdk_find_type_definition("via.Application"):get_method("set_MaxFps(System.Single)"); -- static, native
--
sdk_hook(play_method, nil, function()
	if config.enableFPS then
		local GuiGameStartFsmManager = sdk_get_managed_singleton("snow.gui.fsm.title.GuiGameStartFsmManager");
		if GuiGameStartFsmManager then
			local GameStartStateType = get_GameStartState_method:call(GuiGameStartFsmManager);
			if GameStartStateType ~= nil and GameStartState[GameStartStateType] then
				if config.autoFPS then
					local OptionManager = sdk_get_managed_singleton("snow.StmOptionManager");
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
				set_MaxFps_method:call(nil, config.desiredFPS);
			end
		end
	end
end);

sdk_hook(playEventCommon_method, nil, function()
	if config.enableFPS then
		if config.autoFPS then
			local OptionManager = sdk_get_managed_singleton("snow.StmOptionManager");
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
		set_MaxFps_method:call(nil, config.desiredFPS);
	end
end);

local function save_config()
	json_dump_file("RiseTweaks/config.json", config);
end

re_on_config_save(save_config);

re_on_draw_ui(function()
	local changed = false;
	if imgui_tree_node("RiseTweaks") then
		if imgui_tree_node("Frame Rate") then
			changed, config.enableFPS = imgui_checkbox("Enable", config.enableFPS);
			if config.enableFPS then
				changed, config.autoFPS = imgui_checkbox("Automatic Frame Rate", config.autoFPS);
				if not config.autoFPS then
					changed, config.desiredFPS = imgui_slider_float("Frame Rate", config.desiredFPS, 10.0, 600.0, "%.2f");
				end
			end
			if changed then
				if config.enableFPS then
					if config.autoFPS then
						local OptionManager = sdk_get_managed_singleton("snow.StmOptionManager");
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
					set_MaxFps_method:call(nil, config.desiredFPS);
				end
				save_config();
			end
			imgui_tree_pop();
		end
	end
end);
