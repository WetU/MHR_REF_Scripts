local Constants = require("Constants.Constants");
--
local MaxFps = 119.98;
--
local set_MaxFps_method = sdk.find_type_definition("via.Application"):get_method("set_MaxFps(System.Single)"); -- static
local changeAllMarkerEnable_method = sdk.find_type_definition("snow.access.ObjectAccessManager"):get_method("changeAllMarkerEnable(System.Boolean)");
--
local function applyFps()
	set_MaxFps_method:call(nil, MaxFps);
end

local function PreHook_changeAllMarkerEnable(args)
	if Constants.to_bool(args[3]) == true then
		return;
	end

	changeAllMarkerEnable_method:call(sdk.to_managed_object(args[2]) or sdk.get_managed_singleton("snow.access.ObjectAccessManager"), true);
	return sdk.PreHookResult.SKIP_ORIGINAL;
end
--
sdk.hook(sdk.find_type_definition("snow.eventcut.UniqueEventManager"):get_method("playEventCommon(System.Boolean, System.Int32)"), nil, applyFps);
sdk.hook(changeAllMarkerEnable_method, PreHook_changeAllMarkerEnable);
sdk.hook(sdk.find_type_definition("snow.gui.fsm.questcounter.GuiQuestCounterFsmManager"):get_method("isPressEndQuestCounterOrderStampWithAnim"), Constants.SKIP_ORIGINAL, Constants.RETURN_TRUE);
sdk.hook(sdk.find_type_definition("snow.enemy.EnemyCharacterBase"):get_method("requestMysteryCoreHitMark(snow.enemy.EnemyDef.PartsGroup, snow.hit.EnemyCalcDamageInfo.AfterCalcInfo_DamageSide)"), Constants.SKIP_ORIGINAL);