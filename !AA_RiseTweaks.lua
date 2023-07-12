local Constants = require("Constants.Constants");
if not Constants then
	return;
end
--
local config = Constants.JSON.load_file("RiseTweaks/config.json") or {desiredFPS = 60.0};
if config.desiredFPS == nil then
	config.desiredFPS = 60.0;
end
--
local set_MaxFps_method = Constants.SDK.find_type_definition("via.Application"):get_method("set_MaxFps(System.Single)"); -- static
local changeAllMarkerEnable_method = Constants.SDK.find_type_definition("snow.access.ObjectAccessManager"):get_method("changeAllMarkerEnable(System.Boolean)");
--
local function applyFps()
	set_MaxFps_method:call(nil, config.desiredFPS);
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
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.title.GuiGameStartFsmManager"):get_method("start"), applyFps);
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.eventcut.UniqueEventManager"):get_method("playEventCommon(System.Boolean, System.Int32)"), applyFps);
Constants.SDK.hook(changeAllMarkerEnable_method, PreHook_changeAllMarkerEnable);
--
local function save_config()
	Constants.JSON.dump_file("RiseTweaks/config.json", config);
end

Constants.RE.on_config_save(save_config);
Constants.RE.on_draw_ui(function()
	if Constants.IMGUI.tree_node("RiseTweaks") == true then
		local config_changed = false;
		config_changed, config.desiredFPS = Constants.IMGUI.slider_float("Frame Rate", config.desiredFPS, 10.0, 600.0, "%.2f");
		if config_changed == true then
			applyFps();
			save_config();
		end
		Constants.IMGUI.tree_pop();
	end
end);