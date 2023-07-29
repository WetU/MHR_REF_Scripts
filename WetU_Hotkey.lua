local Constants = require("Constants.Constants");
--
local get_EnableJump_method = Constants.type_definitions.VillageAreaManager_type_def:get_method("get_EnableJump");
local fastTravel_method = Constants.type_definitions.VillageAreaManager_type_def:get_method("fastTravel(snow.stage.StageDef.VillageFastTravelType)");

local VillageFastTravelType_type_def = sdk.find_type_definition("snow.stage.StageDef.VillageFastTravelType");
local ELGADO_CHICHE = VillageFastTravelType_type_def:get_field("v02a06_00"):get_data(nil);
local ELGADO_KITCHEN = VillageFastTravelType_type_def:get_field("v02a06_01"):get_data(nil);
--
local notifyReset_method = Constants.type_definitions.QuestManager_type_def:get_method("notifyReset");
-- Village AreaMove shortcut
local function villageJump(args)
    local VillageAreaManager = sdk.to_managed_object(args[2]) or sdk.get_managed_singleton("snow.VillageAreaManager");
    if get_EnableJump_method:call(VillageAreaManager) == true then
        local fastTravelType = Constants.checkKeyTrg(Constants.Keys.Q_key) == true and ELGADO_CHICHE
            or Constants.checkKeyTrg(Constants.Keys.E_key) == true and ELGADO_KITCHEN
            or nil;

        if fastTravelType ~= nil then
            fastTravel_method:call(VillageAreaManager, fastTravelType);
        end
    end
end
sdk.hook(Constants.type_definitions.VillageAreaManager_type_def:get_method("update"), villageJump);

-- Reset Quest shortcut
local function onUpdateNormalQuest(args)
	if Constants.checkKeyTrg(Constants.Keys.F5_key) == true then
		notifyReset_method:call(sdk.to_managed_object(args[2]) or sdk.get_managed_singleton("snow.QuestManager"));
	end
end
sdk.hook(Constants.type_definitions.QuestManager_type_def:get_method("updateNormalQuest"), onUpdateNormalQuest);