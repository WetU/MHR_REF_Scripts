-- Initialize
local json = json;
local json_dump_file = nil;
local json_load_file = nil;

local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
local sdk_hook = sdk.hook;
local sdk_create_int32 = sdk.create_int32;

local re = re;
local re_on_config_save = re.on_config_save;
local re_on_draw_ui = re.on_draw_ui;

local imgui = imgui;
local imgui_tree_node = imgui.tree_node;
local imgui_checkbox = imgui.checkbox;
local imgui_tree_pop = imgui.tree_pop;

local settings = {};
local jsonAvailable = json ~= nil;

if jsonAvailable then
	json_dump_file = json.dump_file;
	json_load_file = json.load_file;
	local loadedSettings = json_load_file("Fix_Marionette_Camera.json");
	settings = loadedSettings or {enable = true};
end
if settings.enable == nil then
	settings.enable = true;
end
-- Cache
local marionetteType_field = sdk_find_type_definition("snow.CameraManager"):get_field("_MarionetteType");
local UpdateCameraReset_method = sdk_find_type_definition("snow.camera.TargetCamera_Marionette"):get_method("UpdateCameraReset(via.GameObject)");

local MarionetteType_type_def = sdk_find_type_definition("snow.CameraManager.MarionetteType");
local NotResetTypes = {
	[MarionetteType_type_def:get_field("GetOff"):get_data(nil)] = settings.enable,
	[MarionetteType_type_def:get_field("GetOffTryAgainInput"):get_data(nil)] = settings.enable,
	[MarionetteType_type_def:get_field("GetOffFreeRun"):get_data(nil)] = settings.enable
};
local NoReset = sdk_create_int32(0);
-- Main Function
local CameraManager = nil;
sdk_hook(UpdateCameraReset_method, nil, function(retval)
	if not CameraManager or CameraManager:get_reference_count() <= 1 then
		CameraManager = sdk_get_managed_singleton("snow.CameraManager");
	end
	if CameraManager and NotResetTypes[marionetteType_field:get_data(CameraManager)] then
		retval = NoReset;
	end
	return retval;
end);
---- re Callbacks ----
local function save_config()
	if jsonAvailable then
		json_dump_file("Fix_Marionette_Camera.json", settings);
	end
end

re_on_config_save(save_config);

re_on_draw_ui(function()
	local changed = false;
	if imgui_tree_node("Fix Marionette Camera") then
		changed, settings.enable = imgui_checkbox("Enabled", settings.enable);
		imgui_tree_pop();
	else
		if changed then
			if not settings.enable then
				CameraManager = nil;
			end
			save_config();
		end
	end
end);