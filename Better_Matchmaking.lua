local require = require;

local re = re;
local re_on_draw_ui = re.on_draw_ui;

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

re_on_draw_ui(customization_menu.draw);