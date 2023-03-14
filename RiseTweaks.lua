local json = json;
local jsonAvailable = json ~= nil;
local json_load_file = jsonAvailable and json.load_file or nil;
local json_dump_file = jsonAvailable and json.dump_file or nil;

local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_get_native_singleton = sdk.get_native_singleton;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
local sdk_hook = sdk.hook;

local re = re;
local re_on_draw_ui = re.on_draw_ui;
local re_on_config_save = re.on_config_save;

local imgui = imgui;
local imgui_tree_node = imgui.tree_node;
local imgui_checkbox = imgui.checkbox;
local imgui_tree_pop = imgui.tree_pop;
local imgui_slider_float = imgui.slider_float;

local fps_option = {30.0, 60.0, 90.0, 120.0, 144.0, 165.0, 240.0, 600.0};
local config = {};
if json_load_file then
	local config_file = json_load_file("RiseTweaks/config.json");
	config = config_file or {enableFPS = true, autoFPS = true, desiredFPS = fps_option[2]};
end
if config.enableFPS == nil then
	config.enableFPS = true;
end
if config.autoFPS == nil then
	config.autoFPS = true;
end
if config.desiredFPS == nil then
	config.desiredFPS = fps_option[2];
end

local StmOptionManager_type_def = sdk_find_type_definition("snow.StmOptionManager");
local writeGraphicOptionOnIniFile_method = StmOptionManager_type_def:get_method("writeGraphicOptionOnIniFile");
local StmOptionDataContainer_field = StmOptionManager_type_def:get_field("_StmOptionDataContainer");
local getFrameRateOption_method = StmOptionDataContainer_field:get_type():get_method("getFrameRateOption");

local playEventCommon_method = sdk_find_type_definition("snow.eventcut.UniqueEventManager"):get_method("playEventCommon");
local set_MaxFps_method = sdk_find_type_definition("via.Application"):get_method("set_MaxFps(System.Single)");

local function fps_handler(retval)
	if config.enableFPS then
		if config.autoFPS then
			local StmOptionManager = sdk_get_managed_singleton("snow.StmOptionManager");
			if StmOptionManager then
				local FrameRateOption = getFrameRateOption_method:call(stmOptionDataContainer_field:get_data(StmOptionManager));
				if FrameRateOption then
					config.desiredFPS = fps_option[FrameRateOption + 1]; -- lua tables start at 1, the enum doesn't
				end
			end
		end
		local Application = sdk_get_native_singleton("via.Application");
		if Application then
			set_MaxFps_method:call(Application, config.desiredFPS);
		end
	end
	return retval;
end
sdk_hook(writeGraphicOptionOnIniFile_method, nil, fps_handler); -- allows title screen fps changes to appear immediately, if there's a better method to hook, let me know
sdk_hook(playEventCommon_method, nil, fps_handler); -- only bother setting fps for cutscenes

local function save_config()
	if json_dump_file then
		json_dump_file("RiseTweaks/config.json", config);
	end
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
			imgui_tree_pop();
		end
	else
		if changed then
			if config.enableFPS then
				fps_handler();
			end
			save_config();
		end
	end
end);
