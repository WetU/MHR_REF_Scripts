local require = require;
local timeout_fix = require("Better_Matchmaking.timeout_fix");
local region_lock_fix = require("Better_Matchmaking.region_lock_fix");
local misc_fixes = require("Better_Matchmaking.misc_fixes");

if timeout_fix == nil
or region_lock_fix == nil
or misc_fixes == nil then
	return;
end
--
timeout_fix.init_module();
region_lock_fix.init_module();
misc_fixes.init_module();