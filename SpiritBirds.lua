local Constants = require("Constants.Constants");
if Constants == nil then
    return;
end
--
local EcPrefabList_field = Constants.SDK.find_type_definition("snow.envCreature.EnvironmentCreatureManager"):get_field("_EcPrefabList");
local EcPrefabList_get_Item_method = EcPrefabList_field:get_type():get_method("get_Item(System.Int32)");

local Prefab_type_def = EcPrefabList_get_Item_method:get_return_type();
local instantiate_method = Prefab_type_def:get_method("instantiate(via.vec3)");
local get_Standby_method = Prefab_type_def:get_method("get_Standby");
local set_Standby_method = Prefab_type_def:get_method("set_Standby(System.Boolean)");

local destroy_method = instantiate_method:get_return_type():get_method("destroy(via.GameObject)"); -- static
--
local QuestUIFlow_field = Constants.type_definitions.QuestManager_type_def:get_field("_QuestUIFlow");
local QuestUIFlow_None = QuestUIFlow_field:get_type():get_field("None"):get_data(nil);
--
local cachedECitems = nil;
local PRISM_SPIRIBIRD = 14;
local spawned_birds = {};
local autospawn = {
    enabled = true,
    spawned = false
};

local function getECItems()
    if cachedECitems ~= nil then
        return cachedEcitems;
    end

    local EnvironmentCreatureManager = Constants.SDK.get_managed_singleton("snow.envCreature.EnvironmentCreatureManager");
    if EnvironmentCreatureManager ~= nil then
        local ec_list = EcPrefabList_field:get_data(EnvironmentCreatureManager);
        if ec_list ~= nil then
            cachedEcitems = ec_list;
            return ec_list;
        end
    end

    return nil;
end

local function spawn_bird()
    local ec_items = getECItems();
    if ec_items == nil then
        return;
    end

    local ec_bird = EcPrefabList_get_Item_method:call(ec_items, PRISM_SPIRIBIRD);
    if ec_bird == nil then
        return;
    end

    local location = Constants.getCurrentPosition();
    if location == nil then
        return;
    end

    if get_Standby_method:call(ec_bird) ~= true then
        set_Standby_method:call(ec_bird, true);
    end

    local bird = instantiate_method:call(ec_bird, location);
    if bird == nil or Constants.SDK.is_managed_object(bird) ~= true then
        return;
    end

    Constants.LUA.table_insert(spawned_birds, bird);
    autospawn.spawned = true;
end

local function destroy_birds()
    if #spawned_birds > 0 then
        for _, bird in Constants.LUA.pairs(spawned_birds) do
            destroy_method:call(nil, bird);
        end
    end

    spawned_birds = {};
    autospawn.spawned = false;
end

Constants.RE.on_script_reset(destroy_birds);

Constants.SDK.hook(Constants.type_definitions.QuestManager_type_def:get_method("updateQuestUIFlow"), function(args)
    if autospawn.enabled == false or autospawn.spawned == true then
        return;
    end

    local QuestManager = Constants.SDK.to_managed_object(args[2]);
    if QuestManager == nil then
        return;
    end

    local QuestUIFlow = QuestUIFlow_field:get_data(QuestManager);
    if QuestUIFlow == nil or QuestUIFlow ~= QuestUIFlow_None then
        return;
    end

    local MapNo = Constants.getQuestMapNo(QuestManager);
    if MapNo == nil then
        return;
    end

    for _, v in Constants.LUA.pairs(Constants.QuestMapList) do
        if v == MapNo then
            spawn_bird();
            break;
        end
    end
end);

Constants.SDK.hook(Constants.type_definitions.QuestManager_type_def:get_method("onQuestEnd"), destroy_birds);