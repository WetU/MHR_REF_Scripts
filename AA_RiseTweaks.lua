local Constants = require("Constants.Constants");
--
local MAX_FPS = 119.98;
--
local set_MaxFps_method = Constants.type_definitions.Application_type_def:get_method("set_MaxFps(System.Single)"); -- static
--
local function applyFps()
	set_MaxFps_method:call(nil, MAX_FPS);
end

local function PreHook_changeAllMarkerEnable(args)
	if Constants.to_bool(args[3]) ~= true then
		args[3] = Constants.TRUE_POINTER;
	end
end
--
sdk.hook(sdk.find_type_definition("snow.eventcut.UniqueEventManager"):get_method("playEventCommon(System.Boolean, System.Int32)"), nil, applyFps);
sdk.hook(sdk.find_type_definition("snow.access.ObjectAccessManager"):get_method("changeAllMarkerEnable(System.Boolean)"), PreHook_changeAllMarkerEnable);
sdk.hook(sdk.find_type_definition("snow.enemy.EnemyCharacterBase"):get_method("requestMysteryCoreHitMark(snow.enemy.EnemyDef.PartsGroup, snow.hit.EnemyCalcDamageInfo.AfterCalcInfo_DamageSide)"), Constants.SKIP_ORIGINAL);