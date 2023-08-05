local Constants = _G.require("Constants.Constants");

local find_type_definition = Constants.sdk.find_type_definition;
local to_managed_object = Constants.sdk.to_managed_object;
local get_managed_singleton = Constants.sdk.get_managed_singleton;
local hook = Constants.sdk.hook;

local checkKeyTrg = Constants.checkKeyTrg;
local F5 = Constants.Keys.F5;
local F6 = Constants.Keys.F6;
--
local VillageAreaManager_type_def = Constants.type_definitions.VillageAreaManager_type_def;
local fastTravel_method = VillageAreaManager_type_def:get_method("fastTravel(snow.stage.StageDef.VillageFastTravelType)");

local VillageFastTravelType_type_def = find_type_definition("snow.stage.StageDef.VillageFastTravelType");
local ELGADO_CHICHE = VillageFastTravelType_type_def:get_field("v02a06_00"):get_data(nil);
local ELGADO_KITCHEN = VillageFastTravelType_type_def:get_field("v02a06_01"):get_data(nil);
--
local QuestManager_type_def = Constants.type_definitions.QuestManager_type_def;
local notifyReset_method = QuestManager_type_def:get_method("notifyReset");
-- Village AreaMove shortcut
local function jump_Body(villageAreaManager)
    local fastTravelType = checkKeyTrg(F5) == true and ELGADO_CHICHE
        or checkKeyTrg(F6) == true and ELGADO_KITCHEN
        or nil;

    if fastTravelType ~= nil then
        fastTravel_method:call(villageAreaManager, fastTravelType);
    end
end

local VillageAreaManager = nil;
local function PreHook_villageJump(args)
    VillageAreaManager = to_managed_object(args[2]) or get_managed_singleton("snow.VillageAreaManager");
    jump_Body(VillageAreaManager);
end
local function PostHook_villageJump()
    jump_Body(VillageAreaManager);
    VillageAreaManager = nil;
end
hook(VillageAreaManager_type_def:get_method("update"), PreHook_villageJump, PostHook_villageJump);

-- Reset Quest shortcut
local function reset_Body(questManager)
    if checkKeyTrg(F5) == true then
		notifyReset_method:call(questManager);
	end
end

local QuestManager = nil;
local function PreHook_updateNormalQuest(args)
    QuestManager = to_managed_object(args[2]) or get_managed_singleton("snow.QuestManager");
	reset_Body(QuestManager);
end
local function PostHook_updateNormalQuest()
    reset_Body(QuestManager);
    QuestManager = nil;
end
hook(QuestManager_type_def:get_method("updateNormalQuest"), PreHook_updateNormalQuest, PostHook_updateNormalQuest);