local Constants = _G.require("Constants.Constants");

local ResetState_None_Ptr = Constants.sdk.to_ptr(0);
-- Main
local function SkipReset()
	return ResetState_None_Ptr;
end
-- Hook
Constants.sdk.hook(Constants.sdk.find_type_definition("snow.camera.TargetCamera_Marionette"):get_method("UpdateCameraReset(via.GameObject)"), nil, SkipReset);