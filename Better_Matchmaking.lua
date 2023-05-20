local pcall = pcall;
local require = require;

local reframework = reframework;

local re = re;

local imgui = imgui;
local imgui_button = imgui.button;

local utils = require("Better_Matchmaking.utils");
local config = require("Better_Matchmaking.config");

local customization_menu = require("Better_Matchmaking.customization_menu");

local timeout_fix = require("Better_Matchmaking.timeout_fix");
local region_lock_fix = require("Better_Matchmaking.region_lock_fix");
local misc_fixes = require("Better_Matchmaking.misc_fixes");

config.init_module();

customization_menu.init_module();

timeout_fix.init_module();
region_lock_fix.init_module();
misc_fixes.init_module();

re.on_draw_ui(function()
	if imgui_button("Better Matchmaking v" .. config.current_config.version) then
		customization_menu.is_opened = not customization_menu.is_opened;
	end
end);

re.on_frame(function()
	if not reframework:is_drawing_ui() then
		customization_menu.is_opened = false;
	end

	if customization_menu.is_opened then
		pcall(customization_menu.draw);
	end
end);