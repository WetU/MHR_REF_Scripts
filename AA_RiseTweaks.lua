local require = require;
local Constants = require("Constants.Constants");

local hook = Constants.sdk.hook;
local find_type_definition = Constants.sdk.find_type_definition;

local to_bool = Constants.to_bool;
local TRUE_POINTER = Constants.TRUE_POINTER;
local SKIP_ORIGINAL_func = Constants.SKIP_ORIGINAL;
--
local MAX_FPS = 119.98;
--
local set_MaxFps_method = Constants.type_definitions.Application_type_def:get_method("set_MaxFps(System.Single)"); -- static
--
local function applyFps()
	set_MaxFps_method:call(nil, MAX_FPS);
end

local function PreHook_changeAllMarkerEnable(args)
	if to_bool(args[3]) ~= true then
		args[3] = TRUE_POINTER;
	end
end
--
hook(find_type_definition("snow.eventcut.UniqueEventManager"):get_method("playEventCommon(System.Boolean, System.Int32)"), nil, applyFps);
hook(find_type_definition("snow.access.ObjectAccessManager"):get_method("changeAllMarkerEnable(System.Boolean)"), PreHook_changeAllMarkerEnable);
hook(find_type_definition("snow.enemy.EnemyCharacterBase"):get_method("requestMysteryCoreHitMark(snow.enemy.EnemyDef.PartsGroup, snow.hit.EnemyCalcDamageInfo.AfterCalcInfo_DamageSide)"), SKIP_ORIGINAL_func);