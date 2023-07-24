local Constants = require("Constants.Constants");
if Constants == nil then
	return;
end
-- Cache
local ResetState_None = Constants.SDK.find_type_definition("snow.camera.PlayerCamera.ResetState"):get_field("None"):get_data(nil);

local get_MarionetteCameraType_method = Constants.type_definitions.CameraManager_type_def:get_method("get_MarionetteCameraType");
local MarionetteCameraType_type_def = get_MarionetteCameraType_method:get_return_type();
local NotResetTypes = {
	["GetOff"] = MarionetteCameraType_type_def:get_field("GetOff"):get_data(nil),
	["GetOffTryAgainInput"] = MarionetteCameraType_type_def:get_field("GetOffTryAgainInput"):get_data(nil),
	["GetOffFreeRun"] = MarionetteCameraType_type_def:get_field("GetOffFreeRun"):get_data(nil)
};
local NotResetPtr = Constants.SDK.to_ptr(ResetState_None);
-- Main
local function SkipReset(retval)
	if Constants.SDK.to_int64(retval) ~= ResetState_None then
		local CameraManager = Constants.SDK.get_managed_singleton("snow.CameraManager");
		if CameraManager ~= nil then
			local MarionetteCameraType = get_MarionetteCameraType_method:call(CameraManager);
			if MarionetteCameraType ~= nil then
				for _, v in Constants.LUA.pairs(NotResetTypes) do
					if MarionetteCameraType == v then
						return NotResetPtr;
					end
				end
			end
		end
	end

	return retval;
end
-- Hook
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.camera.TargetCamera_Marionette"):get_method("UpdateCameraReset(via.GameObject)"), nil, SkipReset);