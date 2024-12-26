local Constants = _G.require("Constants.Constants");

local sdk = Constants.sdk;
local get_hook_storage = Constants.get_hook_storage;
local SKIP_ORIGINAL_func = Constants.SKIP_ORIGINAL_func;

local hook = sdk.hook;
local find_type_definition = sdk.find_type_definition;
local to_managed_object = sdk.to_managed_object;
--
local MAX_FPS = 119.98;
--
local set_MaxFps_method = Constants.type_definitions.Application_type_def:get_method("set_MaxFps(System.Single)"); -- static
--
local changeAllMarkerEnable_method = find_type_definition("snow.access.ObjectAccessManager"):get_method("changeAllMarkerEnable(System.Boolean)");
local function applyFps()
	set_MaxFps_method:call(nil, MAX_FPS);
end

local hookNeed = true;
local function PreHook_changeAllMarkerEnable(args)
	if hookNeed == true then
		get_hook_storage()["ObjectAccessManager"] = to_managed_object(args[2]);
		return SKIP_ORIGINAL_func;
	end

	hookNeed = true;
end
local function PostHook_changeAllMarkerEnable()
	local ObjectAccessManager = get_hook_storage()["ObjectAccessManager"];
	if ObjectAccessManager ~= nil then
		hookNeed = false;
		changeAllMarkerEnable_method:call(ObjectAccessManager, true);
	end
end
--
hook(find_type_definition("snow.eventcut.UniqueEventManager"):get_method("playEventCommon(System.Boolean, System.Int32)"), nil, applyFps);
hook(changeAllMarkerEnable_method, PreHook_changeAllMarkerEnable, PostHook_changeAllMarkerEnable);
hook(find_type_definition("snow.enemy.EnemyCharacterBase"):get_method("requestMysteryCoreHitMark(snow.enemy.EnemyDef.PartsGroup, snow.hit.EnemyCalcDamageInfo.AfterCalcInfo_DamageSide)"), SKIP_ORIGINAL_func);
