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
local set_MaxFps_method = Constants.SDK.find_type_definition("via.Application"):get_method("set_MaxFps(System.Single)"); -- static

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
--
local function getAutoFps()
	local OptionManager = Constants.SDK.get_managed_singleton("snow.StmOptionManager");
	if OptionManager then
		local OptionDataContainer = StmOptionDataContainer_field:get_data(OptionManager);
		if OptionDataContainer then
			local FrameRateOption = getFrameRateOption_method:call(OptionDataContainer);
			if FrameRateOption ~= nil then
				config.desiredFPS = FrameRate[FrameRateOption];
			end
		end
	end
end

local function applyFps()
	if config.enableFPS then
		if config.autoFPS then
			getAutoFps();
		end
		set_MaxFps_method:call(nil, config.desiredFPS);
	end
end
--
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.title.GuiGameStartFsmManager"):get_method("start"), nil, applyFps);
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.eventcut.UniqueEventManager"):get_method("playEventCommon(System.Boolean, System.Int32)"), nil, applyFps);
--
local function save_config()
	Constants.JSON.dump_file("RiseTweaks/config.json", config);
end

Constants.RE.on_script_reset(applyFps);
Constants.RE.on_config_save(save_config);
Constants.RE.on_draw_ui(function()
	if Constants.IMGUI.tree_node("RiseTweaks") then
		if Constants.IMGUI.tree_node("Frame Rate") then
			local config_changed = false;
			local changed = false;
			config_changed, config.enableFPS = Constants.IMGUI.checkbox("Enable", config.enableFPS);
			if config.enableFPS then
				changed, config.autoFPS = Constants.IMGUI.checkbox("Automatic Frame Rate", config.autoFPS);
				config_changed = config_changed or changed;
				if not config.autoFPS then
					changed, config.desiredFPS = Constants.IMGUI.slider_float("Frame Rate", config.desiredFPS, 10.0, 600.0, "%.2f");
					config_changed = config_changed or changed;
				end
			end
			if config_changed then
				if config.enableFPS then
					applyFps();
				end
				save_config();
			end
			Constants.IMGUI.tree_pop();
		end
		Constants.IMGUI.tree_pop();
	end
end);