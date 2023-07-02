local require = require;
local Constants = require("Constants.Constants");
local utils = require("Better_Matchmaking.utils");
local config = require("Better_Matchmaking.config");
local customization_menu = require("Better_Matchmaking.customization_menu");
local timeout_fix = require("Better_Matchmaking.timeout_fix");
local region_lock_fix = require("Better_Matchmaking.region_lock_fix");
local misc_fixes = require("Better_Matchmaking.misc_fixes");

if not Constants
or not utils
or not config
or not customization_menu
or not timeout_fix
or not region_lock_fix
or not misc_fixes then
	return;
end
--
local reframework = reframework;

config.init_module();
customization_menu.init_module();
timeout_fix.init_module();
region_lock_fix.init_module();
misc_fixes.init_module();

Constants.RE.on_draw_ui(function()
	if Constants.IMGUI.button("Better Matchmaking v" .. config.current_config.version) == true then
		customization_menu.is_opened = not customization_menu.is_opened;
	end
end);

Constants.RE.on_frame(function()
	if customization_menu.is_opened == true then
		if reframework:is_drawing_ui() == false then
			customization_menu.is_opened = false;
		else
			Constants.LUA.pcall(customization_menu.draw);
		end
	end
end);