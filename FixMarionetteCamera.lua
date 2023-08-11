local Constants = _G.require("Constants.Constants");

local find_type_definition = Constants.sdk.find_type_definition;
local hook = Constants.sdk.hook;
local to_ptr = Constants.sdk.to_ptr;
-- Cache
local ResetState_None = find_type_definition("snow.camera.PlayerCamera.ResetState"):get_field("None"):get_data(nil);
-- Main
local ResetState_None_Ptr = to_ptr(ResetState_None);
local function SkipReset()
	return ResetState_None_Ptr;
end
-- Hook
hook(find_type_definition("snow.camera.TargetCamera_Marionette"):get_method("UpdateCameraReset(via.GameObject)"), nil, SkipReset);