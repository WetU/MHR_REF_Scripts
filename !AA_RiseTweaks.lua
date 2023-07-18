local Constants = require("Constants.Constants");
if Constants == nil then
	return;
end
--
local MaxFps = 119.98;
--
local set_MaxFps_method = Constants.SDK.find_type_definition("via.Application"):get_method("set_MaxFps(System.Single)"); -- static
local changeAllMarkerEnable_method = Constants.SDK.find_type_definition("snow.access.ObjectAccessManager"):get_method("changeAllMarkerEnable(System.Boolean)");
--
local function applyFps()
	set_MaxFps_method:call(nil, MaxFps);
end

local function PreHook_changeAllMarkerEnable(args)
	if Constants.to_bool(args[3]) == true then
		return;
	end

	local ObjectAccessManager = Constants.SDK.to_managed_object(args[2]);
	if ObjectAccessManager == nil then
		return;
	end

	changeAllMarkerEnable_method:call(ObjectAccessManager, true);
	return Constants.SDK.SKIP_ORIGINAL;
end
--
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.eventcut.UniqueEventManager"):get_method("playEventCommon(System.Boolean, System.Int32)"), nil, applyFps);
Constants.SDK.hook(changeAllMarkerEnable_method, PreHook_changeAllMarkerEnable);
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.questcounter.GuiQuestCounterFsmManager"):get_method("isPressEndQuestCounterOrderStampWithAnim"), Constants.SKIP_ORIGINAL, Constants.Return_TRUE);