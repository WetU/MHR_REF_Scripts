local Constants = require("Constants.Constants");
if not Constants then
    return;
end
--
local this = {};
--
local ProgressOwlNestManager_type_def = Constants.SDK.find_type_definition("snow.progress.ProgressOwlNestManager");
local supply_method = ProgressOwlNestManager_type_def:get_method("supply");
local get_SaveData_method = ProgressOwlNestManager_type_def:get_method("get_SaveData");
local StackItemCount = ProgressOwlNestManager_type_def:get_field("StackItemCount"):get_data(nil);

local ProgressOwlNestSaveData_type_def = get_SaveData_method:get_return_type();
local kamuraStackCount_field = ProgressOwlNestSaveData_type_def:get_field("_StackCount");
local elgadoStackCount_field = ProgressOwlNestSaveData_type_def:get_field("_StackCount2");
--
local VillageAreaManager_type_def = Constants.SDK.find_type_definition("snow.VillageAreaManager");
local get__CurrentAreaNo_method = VillageAreaManager_type_def:get_method("get__CurrentAreaNo");
local set__CurrentAreaNo_method = VillageAreaManager_type_def:get_method("set__CurrentAreaNo(snow.stage.StageDef.AreaNoType)");

local AreaNoType_type_def = get__CurrentAreaNo_method:get_return_type();
local BUDDY_PLAZA = AreaNoType_type_def:get_field("No02"):get_data(nil);
local OUTPOST = AreaNoType_type_def:get_field("No06"):get_data(nil);
--
function this.Supply()
    local ProgressOwlNestManager = Constants.SDK.get_managed_singleton("snow.progress.ProgressOwlNestManager");
    if ProgressOwlNestManager == nil then
        return;
    end

    local SaveData = get_SaveData_method:call(ProgressOwlNestManager);
    if SaveData == nil then
        return;
    end

    local VillageAreaManager = Constants.SDK.get_managed_singleton("snow.VillageAreaManager");
    if VillageAreaManager == nil then
        return;
    end

    local savedAreaNo = get__CurrentAreaNo_method:call(VillageAreaManager);
    if savedAreaNo == nil then
        return;
    end

    if kamuraStackCount_field:get_data(SaveData) == StackItemCount then
        if savedAreaNo == BUDDY_PLAZA then
            supply_method:call(ProgressOwlNestManager);
        else
            set__CurrentAreaNo_method:call(VillageAreaManager, BUDDY_PLAZA);
            supply_method:call(ProgressOwlNestManager);
            set__CurrentAreaNo_method:call(VillageAreaManager, savedAreaNo);
        end
    end
    if elgadoStackCount_field:get_data(SaveData) == StackItemCount then
        if savedAreaNo == OUTPOST then
            supply_method:call(ProgressOwlNestManager);
        else
            set__CurrentAreaNo_method:call(VillageAreaManager, OUTPOST);
            supply_method:call(ProgressOwlNestManager);
            set__CurrentAreaNo_method:call(VillageAreaManager, savedAreaNo);
        end
    end
end

return this;