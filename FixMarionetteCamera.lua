local require = require;
local Constants = require("Constants.Constants");

local ipairs = Constants.lua.ipairs;

local find_type_definition = Constants.sdk.find_type_definition;
local to_ptr = Constants.sdk.to_ptr;
local to_int64 = Constants.sdk.to_int64;
local get_managed_singleton = Constants.sdk.get_managed_singleton;
local hook = Constants.sdk.hook;
-- Cache
local ResetState_None = find_type_definition("snow.camera.PlayerCamera.ResetState"):get_field("None"):get_data(nil);

local get_MarionetteCameraType_method = Constants.type_definitions.CameraManager_type_def:get_method("get_MarionetteCameraType");
local MarionetteCameraType_type_def = get_MarionetteCameraType_method:get_return_type();
local NotResetTypes = {
	[MarionetteCameraType_type_def:get_field("GetOff"):get_data(nil)] = true,
	[MarionetteCameraType_type_def:get_field("GetOffTryAgainInput"):get_data(nil)] = true,
	[MarionetteCameraType_type_def:get_field("GetOffFreeRun"):get_data(nil)] = true
};
local NotResetPtr = to_ptr(ResetState_None);
-- Main
local function SkipReset(retval)
	return (to_int64(retval) ~= ResetState_None and NotResetTypes[get_MarionetteCameraType_method:call(get_managed_singleton("snow.CameraManager"))] == true) and NotResetPtr or retval;
end
-- Hook
hook(find_type_definition("snow.camera.TargetCamera_Marionette"):get_method("UpdateCameraReset(via.GameObject)"), nil, SkipReset);