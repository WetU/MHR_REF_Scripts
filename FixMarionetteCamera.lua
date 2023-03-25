-- Initialize
local json = json;
local jsonAvailable = json ~= nil;
local json_load_file = jsonAvailable and json.load_file or nil;
local json_dump_file = jsonAvailable and json.dump_file or nil;

local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
local sdk_create_int32 = sdk.create_int32;
local sdk_hook = sdk.hook;

local re = re;
local re_on_config_save = re.on_config_save;
local re_on_draw_ui = re.on_draw_ui;

local imgui = imgui;
local imgui_tree_node = imgui.tree_node;
local imgui_checkbox = imgui.checkbox;
local imgui_tree_pop = imgui.tree_pop;

local settings = {};
if json_load_file then
	local loadedSettings = json_load_file("Fix_Marionette_Camera.json");
	settings = loadedSettings or {enable = true};
end
if settings.enable == nil then
	settings.enable = true;
end
-- Cache
local UpdateCameraReset_method = sdk_find_type_definition("snow.camera.TargetCamera_Marionette"):get_method("UpdateCameraReset(via.GameObject)");
local get_MarionetteCameraType_method = sdk_find_type_definition("snow.CameraManager"):get_method("get_MarionetteCameraType");
local MarionetteType_type_def = get_MarionetteCameraType_method:get_return_type();
local NotResetTypes = {
	[MarionetteType_type_def:get_field("GetOff"):get_data(nil)] = settings.enable,
	[MarionetteType_type_def:get_field("GetOffTryAgainInput"):get_data(nil)] = settings.enable,
	[MarionetteType_type_def:get_field("GetOffFreeRun"):get_data(nil)] = settings.enable
};
-- Main Function
local NoReset = sdk_create_int32(0);
sdk_hook(UpdateCameraReset_method, nil, function(retval)
	if settings.enable then
		local CameraManager = sdk_get_managed_singleton("snow.CameraManager");
		if CameraManager then
			local MarionetteCameraType = get_MarionetteCameraType_method:call(CameraManager);
			if MarionetteCameraType ~= nil and NotResetTypes[MarionetteCameraType] then
				retval = NoReset;
			end
		end
	end
	return retval;
end);
---- re Callbacks ----
local function save_config()
	if json_dump_file then
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
			save_config();
		end
	end
end);