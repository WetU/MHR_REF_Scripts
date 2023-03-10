local tonumber = tonumber;
local tostring = tostring;

local json = json;
local json_dump_file = nil;
local json_load_file = nil;

local sdk = sdk;
local sdk_get_native_singleton = sdk.get_native_singleton;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_hook = sdk.hook;

local re = re;
local re_on_draw_ui = re.on_draw_ui;
local re_on_config_save = re.on_config_save;

local imgui = imgui;
local imgui_tree_node = imgui.tree_node;
local imgui_checkbox = imgui.checkbox;
local imgui_combo = imgui.combo;
local imgui_tree_pop = imgui.tree_pop;
local imgui_drag_float = imgui.drag_float;

local fps_option = {"30.0", "60.0", "90.0", "120.0", "144.0", "165.0", "240.0", "600.0"};
local config = {};
local config_path = "RiseTweaks/config.json";
local jsonAvailable = json ~= nil;
if jsonAvailable then
	json_dump_file = json.dump_file;
	json_load_file = json.load_file;
	local config_file = json_load_file(config_path);
	config = config_file or {enableFPS = true, autoFPS = true, desiredFPS = tonumber(fps_option[2]), enableQuality = false, desiredQuality = 1.0};
end
if config.enableFPS == nil then
	config.enableFPS = true;
end
if config.autoFPS == nil then
	config.autoFPS = true;
end
if config.enableQuality == nil then
	config.enableQuality = false;
end
if config.desiredQuality == nil then
	config.desiredQuality = 1.0;
end
local found = false;
if config.desiredFPS then
	for i = 1, #fps_option do
		if fps_option[i] == tostring(config.desiredFPS) then
			found = true;
			break;
		end
	end
end
if not found then
	config.desiredFPS = tonumber(fps_option[2]);
end

local Application = nil;
local Renderer = nil;

local StmOptionManager = nil;

local stmOptionManager_type_def = sdk_find_type_definition("snow.StmOptionManager");
local writeGraphicOptionOnIniFile_method = stmOptionManager_type_def:get_method("writeGraphicOptionOnIniFile");
local stmOptionDataContainer_field = stmOptionManager_type_def:get_field("_StmOptionDataContainer");
local getFrameRateOption_method = stmOptionDataContainer_field:get_type():get_method("getFrameRateOption");

local playEventCommon_method = sdk_find_type_definition("snow.eventcut.UniqueEventManager"):get_method("playEventCommon");
local setSamplerQuality_method = sdk_find_type_definition("snow.RenderAppManager"):get_method("setSamplerQuality");
local set_MaxFps_method = sdk_find_type_definition("via.Application"):get_method("set_MaxFps");
local set_ImageQualityRate_method = sdk_find_type_definition("via.render.Renderer"):get_method("set_ImageQualityRate");

function fps_handler(retval)
	if config.enableFPS then
		if config.autoFPS then
			if not StmOptionManager or StmOptionManager:get_reference_count() <= 1 then
				StmOptionManager = sdk_get_managed_singleton("snow.StmOptionManager");
			end
			if StmOptionManager then
				local FrameRateOption = getFrameRateOption_method:call(stmOptionDataContainer_field:get_data(StmOptionManager));
				if FrameRateOption then
					config.desiredFPS = tonumber(fps_option[FrameRateOption + 1]); -- lua tables start at 1, the enum doesn't
				end
			end
		end
		if not Application then
			Application = sdk_get_native_singleton("via.Application");
		end
		if Application then
			set_MaxFps_method:call(Application, config.desiredFPS);
		end
	end
	return retval;
end
sdk_hook(writeGraphicOptionOnIniFile_method, nil, fps_handler); -- allows title screen fps changes to appear immediately, if there's a better method to hook, let me know
sdk_hook(playEventCommon_method, nil, fps_handler); -- only bother setting fps for cutscenes

function quality_handler(retval)
	if config.enableQuality then
		if not Renderer then
			Renderer = sdk_get_native_singleton("via.render.Renderer");
		end
		if Renderer then
			set_ImageQualityRate_method:call(Renderer, config.desiredQuality);
		end
	end
	return retval;
end
sdk_hook(setSamplerQuality_method, nil, quality_handler); -- set image quality whenever the scene changes, this seems to be be called whenever a graphical setting is changed that would cause the game to redo the sampler.

local function save_config()
	if jsonAvailable then
		json_dump_file(config_path, config);
	end
end

re_on_config_save(save_config);

local function FindIndex(table, value)
    for i = 1, #table do
        if table[i] == value then
            return i;
        end
    end
    return nil;
end

re_on_draw_ui(function()
	local changed = false;
	if imgui_tree_node("RiseTweaks") then
		if imgui_tree_node("Frame Rate") then
			changed, config.enableFPS = imgui_checkbox("Enable", config.enableFPS);
			if config.enableFPS then
				changed, config.autoFPS = imgui_checkbox("Automatic Frame Rate", config.autoFPS);
				if not config.autoFPS then
					local desiredFPS = nil;
					for i = 1, #fps_option do
						if table[i] == tostring(config.desiredFPS) then
							desiredFPS = i;
							break;
						end
					end
					changed, desiredFPS = imgui_combo("Frame Rate", desiredFPS, fps_option);
					config.desiredFPS = tonumber(fps_option[desiredFPS]);
				end
			end
			imgui_tree_pop();
		end
		
		if imgui_tree_node("Image Quality") then
			changed, config.enableQuality = imgui_checkbox("Enable", config.enableQuality);
			if config.enableQuality then
				changed, config.desiredQuality = imgui_drag_float("Image Quality", config.desiredQuality, 0.05, 0.1, 4.0);
			end
			imgui_tree_pop();
		end
	else
		if changed then
			if not config.enableFPS then
				StmOptionManager = nil;
				Application = nil;
			else
				fps_handler();
			end
			if not config.enableQuality then
				Renderer = nil;
			else
				quality_handler();
			end
			save_config();
		end
	end
end);
