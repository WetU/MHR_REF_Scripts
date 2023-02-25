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

local imgui = imgui;
local imgui_tree_node = imgui.tree_node;
local imgui_checkbox = imgui.checkbox;
local imgui_slider_int = imgui.slider_int;
local imgui_tree_pop = imgui.tree_pop;
local imgui_drag_float = imgui.drag_float;
local imgui_button = imgui.button;

local ipairs = ipairs;
local type = type;
local require = require;

local fps_option = {30.0, 60.0, 90.0, 120.0, 144.0, 165.0, 240.0, 600.0};
local config = {};
local config_path = "RiseTweaks/config.json";
local jsonAvailable = json ~= nil;
if jsonAvailable == true then
	json_dump_file = json.dump_file;
	json_load_file = json.load_file;
	local config_file = json_load_file(config_path);
	config = config_file ~= nil and config_file or {enableFPS = true, autoFPS = true, desiredFPS = fps_option[2], enableMenuLimit = true, menuLimit = fps_option[2], enableQuality = false, desiredQuality = 1.0};
end

if config.enableFPS == nil then
	config.enableFPS = true;
end
if config.autoFPS == nil then
	config.autoFPS = true;
end
if config.desiredFPS == nil then
	config.desiredFPS = fps_option[2];
elseif config.desiredFPS < 10.0 then
	config.desiredFPS = 10.0;
elseif config.desiredFPS > fps_option[8] then
	config.desiredFPS = fps_option[8];
end
if config.enableMenuLimit == nil then
	config.enableMenuLimit = true;
end
if config.menuLimit == nil then
	config.menuLimit = fps_option[2];
elseif config.menuLimit < 10.0 then
	config.menuLimit = 10.0;
elseif config.menuLimit > fps_option[8] then
	config.menuLimit = fps_option[8];
end
if config.enableQuality == nil then
	config.enableQuality = false;
end
if config.desiredQuality == nil then
	config.desiredQuality = 1.0;
end

local Application = nil;
local Renderer = nil;

local StmOptionManager = nil;
local QuestManager = nil;

local stmOptionManager_type_def = sdk_find_type_definition("snow.StmOptionManager");
local writeGraphicOptionOnIniFile_method = stmOptionManager_type_def:get_method("writeGraphicOptionOnIniFile");
local stmOptionDataContainer_field = stmOptionManager_type_def:get_field("_StmOptionDataContainer");
local getFrameRateOption_method = stmOptionDataContainer_field:get_type():get_method("getFrameRateOption");

local NpcCamera_type_def = sdk_find_type_definition("snow.NpcCamera");
local requestMediumCloseUpCamera_method = NpcCamera_type_def:get_method("requestMediumCloseUpCamera");
local requestReleaseCamera_method = NpcCamera_type_def:get_method("requestReleaseCamera");

local GuiItemBoxMenu_type_def = sdk_find_type_definition("snow.gui.fsm.itembox.GuiItemBoxMenu");
local ItemBoxMenu_doOpen_method = GuiItemBoxMenu_type_def:get_method("doOpen");
local ItemBoxMenu_doClose_method = GuiItemBoxMenu_type_def:get_method("doClose");

local GuiPauseWindow_type_def = sdk_find_type_definition("snow.gui.GuiPauseWindow");
local PauseWindow_doOpen_method = GuiPauseWindow_type_def:get_method("doOpen");
local PauseWindow_doClose_method = GuiPauseWindow_type_def:get_method("doClose");

local GuiQuestBoard_type_def = sdk_find_type_definition("snow.gui.GuiQuestBoard");
local QuestBoard_doOpen_method = GuiQuestBoard_type_def:get_method("doOpen");
local QuestBoard_cancelMenuCommon_method = GuiQuestBoard_type_def:get_method("cancelMenuCommon");

local playEventCommon_method = sdk_find_type_definition("snow.eventcut.UniqueEventManager"):get_method("playEventCommon");
local setSamplerQuality_method = sdk_find_type_definition("snow.RenderAppManager"):get_method("setSamplerQuality");
local set_MaxFps_method = sdk_find_type_definition("via.Application"):get_method("set_MaxFps");
local set_ImageQualityRate_method = sdk_find_type_definition("via.render.Renderer"):get_method("set_ImageQualityRate");

local questStatus_field = sdk_find_type_definition("snow.QuestManager"):get_field("_QuestStatus");

function fps_handler(retval)
	if config.enableFPS then
		if config.autoFPS then
			if not StmOptionManager or StmOptionManager:get_reference_count() <= 1 then
				StmOptionManager = sdk_get_managed_singleton("snow.StmOptionManager");
			end
			local FrameRateOption = getFrameRateOption_method:call(stmOptionDataContainer_field:get_data(StmOptionManager));
			if FrameRateOption ~= nil then
				config.desiredFPS = fps_option[FrameRateOption + 1]; -- lua tables start at 1, the enum doesn't
			end
		end
		if not Application then
			Application = sdk_get_native_singleton("via.Application");
		end
		if Application ~= nil then
			set_MaxFps_method:call(Application, config.desiredFPS);
		end
	end
	return retval;
end
sdk_hook(writeGraphicOptionOnIniFile_method, nil, fps_handler); -- allows title screen fps changes to appear immediately, if there's a better method to hook, let me know
sdk_hook(playEventCommon_method, nil, fps_handler); -- only bother setting fps for cutscenes

function quality_handler(retval)
	if config.enableQuality then
		if not Renderer or Renderer:get_reference_count() <= 1 then
			Renderer = sdk_get_native_singleton("via.render.Renderer");
		end
		if Renderer ~= nil then
			set_ImageQualityRate_method:call(Renderer, config.desiredQuality);
		end
	end
	return retval;
end
sdk_hook(setSamplerQuality_method, nil, quality_handler); -- set image quality whenever the scene changes, this seems to be be called whenever a graphical setting is changed that would cause the game to redo the sampler.

local function limit_max_fps()
	if config.enableMenuLimit then
		if not Application then
			Application = sdk_get_native_singleton("via.Application");
		end
		if Application ~= nil then
			set_MaxFps_method:call(Application, config.menuLimit);
		end
	end
end
local function limit_max_fps_if_in_base()
	if config.enableMenuLimit then
		if not QuestManager or QuestManager:get_reference_count() <= 1 then
			QuestManager = sdk_get_managed_singleton("snow.QuestManager");
		end
		if QuestManager ~= nil and questStatus_field:get_data(QuestManager) == 0 then
			if not Application then
				Application = sdk_get_native_singleton("via.Application");
			end
			if Application ~= nil then
				set_MaxFps_method:call(Application, config.menuLimit);
			end
		end
	end
end
local function reset_max_fps()
	if config.enableMenuLimit then
		if not StmOptionManager or StmOptionManager:get_reference_count() <= 1 then
			StmOptionManager = sdk_get_managed_singleton("snow.StmOptionManager");
		end
		if StmOptionManager ~= nil then
			local FrameRateOption = getFrameRateOption_method:call(stmOptionDataContainer_field:get_data(StmOptionManager));
			if FrameRateOption ~= nil then
				if not Application then
					Application = sdk_get_native_singleton("via.Application");
				end
				if Application ~= nil then
					set_MaxFps_method:call(Application, fps_option[FrameRateOption + 1]);
				end
			end
		end
	end
end
sdk_hook(requestMediumCloseUpCamera_method, limit_max_fps_if_in_base);
sdk_hook(requestReleaseCamera_method, reset_max_fps);

sdk_hook(ItemBoxMenu_doOpen_method, limit_max_fps_if_in_base);
sdk_hook(ItemBoxMenu_doClose_method, reset_max_fps);

sdk_hook(PauseWindow_doOpen_method, limit_max_fps);
sdk_hook(PauseWindow_doClose_method, reset_max_fps);

sdk_hook(QuestBoard_doOpen_method, limit_max_fps_if_in_base);
sdk_hook(QuestBoard_cancelMenuCommon_method, reset_max_fps);

re_on_draw_ui(function()
	if imgui_tree_node("RiseTweaks") then
		local changed = false;
		if imgui_tree_node("Frame Rate") then
			changed, config.enableFPS = imgui_checkbox("Enable", config.enableFPS);
			changed, config.enableMenuLimit = imgui_checkbox("Enable MenuLimit", config.enableMenuLimit);
			if config.enableFPS then
				changed, config.autoFPS = imgui_checkbox("Automatic Frame Rate", config.autoFPS);
				if not config.autoFPS then
					changed, config.desiredFPS = imgui_slider_int("Frame Rate", config.desiredFPS, 10, 600);
				end
			end
			if config.enableMenuLimit then
				changed, config.menuLimit = imgui_slider_int("Frame Rate Limit", config.menuLimit, 10, 600);
			end
			if changed then
				if config.enableMenuLimit == false then
					QuestManager = nil;
					if config.enableFPS == false then
						StmOptionManager = nil;
						Application = nil;
					end
				end
				if config.enableFPS == true then
					fps_handler();
				end
			end
			imgui_tree_pop();
		end
		
		changed = false;
		
		if imgui_tree_node("Image Quality") then
			changed, config.enableQuality = imgui_checkbox("Enable", config.enableQuality);
			if config.enableQuality then
				changed, config.desiredQuality = imgui_drag_float("Image Quality", config.desiredQuality, 0.05, 0.1, 4.0);
			end
			if changed then
				if config.enableQuality == false then
					Renderer = nil;
				else				
					quality_handler();
				end
			end
			imgui_tree_pop();
		end
		
		if imgui_button("Save Settings") then
			if json_load_file(config_path) ~= config then
				json_dump_file(config_path, config);
			end
		end
		
		imgui_tree_pop();
	end
end);
