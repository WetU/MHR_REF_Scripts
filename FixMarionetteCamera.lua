-- Initialize
local pairs = pairs;

local json = json;

local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
local sdk_to_int64 = sdk.to_int64;

local re = re;

local imgui = imgui;
local imgui_tree_node = imgui.tree_node;
local imgui_checkbox = imgui.checkbox;
local imgui_tree_pop = imgui.tree_pop;

local settings = json.load_file("Fix_Marionette_Camera.json") or {enable = true};
if settings.enable == nil then
	settings.enable = true;
end
-- Cache
local ResetState_None = sdk_find_type_definition("snow.camera.PlayerCamera.ResetState"):get_field("None"):get_data(nil);

local get_MarionetteCameraType_method = sdk_find_type_definition("snow.CameraManager"):get_method("get_MarionetteCameraType"); -- retval

local MarionetteCameraType_type_def = get_MarionetteCameraType_method:get_return_type();
local NotResetTypes = {
	[MarionetteCameraType_type_def:get_field("GetOff"):get_data(nil)] = true,
	[MarionetteCameraType_type_def:get_field("GetOffTryAgainInput"):get_data(nil)] = true,
	[MarionetteCameraType_type_def:get_field("GetOffFreeRun"):get_data(nil)] = true
};
-- Main Function
local NoReset = sdk.to_ptr(ResetState_None);
sdk.hook(sdk_find_type_definition("snow.camera.TargetCamera_Marionette"):get_method("UpdateCameraReset(via.GameObject)"), nil, function(retval)
	if settings.enable and (sdk_to_int64(retval) & 0xFFFFFFFF) ~= ResetState_None then
		local CameraManager = sdk_get_managed_singleton("snow.CameraManager");
		if CameraManager then
			local MarionetteCameraType = get_MarionetteCameraType_method:call(CameraManager);
			if MarionetteCameraType ~= nil and NotResetTypes[MarionetteCameraType] then
				return NoReset;
			end
		end
	end
	return retval;
end);
---- re Callbacks ----
local function save_config()
	json.dump_file("Fix_Marionette_Camera.json", settings);
end

re.on_config_save(save_config);

re.on_draw_ui(function()
	local changed = false;
	if imgui_tree_node("Fix Marionette Camera") then
		changed, settings.enable = imgui_checkbox("Enabled", settings.enable);
		if changed then
			save_config();
		end
		imgui_tree_pop();
	end
end);