local Constants = require("Constants.Constants");
if not Constants then
    return;
end
--
local this = {};
--
local ProgressOwlNestManager_type_def = Constants.SDK.find_type_definition("snow.progress.ProgressOwlNestManager");
local Owl_supply_method = ProgressOwlNestManager_type_def:get_method("supply");
local get_SaveData_method = ProgressOwlNestManager_type_def:get_method("get_SaveData"); -- retval

local progressOwlNestSaveData_type_def = get_SaveData_method:get_return_type();
local kamuraStackCount_field = progressOwlNestSaveData_type_def:get_field("_StackCount");
local elgadoStackCount_field = progressOwlNestSaveData_type_def:get_field("_StackCount2");
--
local VillageAreaManager_type_def = Constants.SDK.find_type_definition("snow.VillageAreaManager");
local get__CurrentAreaNo_method = VillageAreaManager_type_def:get_method("get__CurrentAreaNo"); -- retval
local set__CurrentAreaNo_method = VillageAreaManager_type_def:get_method("set__CurrentAreaNo(snow.stage.StageDef.AreaNoType)");

local AreaNoType_type_def = get__CurrentAreaNo_method:get_return_type();
local BUDDY_PLAZA = AreaNoType_type_def:get_field("No02"):get_data(nil);
local OUTPOST = AreaNoType_type_def:get_field("No06"):get_data(nil);
--
function this.SupplyCohoot()
    local ProgressOwlNestManager = Constants.SDK.get_managed_singleton("snow.progress.ProgressOwlNestManager");
    if ProgressOwlNestManager then
        local saveData = get_SaveData_method:call(ProgressOwlNestManager);
        if saveData then
            local kamuraStack = kamuraStackCount_field:get_data(saveData);
            local elgadoStack = elgadoStackCount_field:get_data(saveData);

            local tempNum = 0;
            if kamuraStack == 5 then
                tempNum = tempNum + 1;
            end
            if elgadoStack == 5 then
                tempNum = tempNum + 2;
            end

            if tempNum > 0 then
                local VillageAreaManager = Constants.SDK.get_managed_singleton("snow.VillageAreaManager");
                if VillageAreaManager then
                    local savedAreaNo = get__CurrentAreaNo_method:call(VillageAreaManager);
                    if tempNum == 1 then
                        if savedAreaNo == BUDDY_PLAZA then
                            Owl_supply_method:call(ProgressOwlNestManager);
                        else
                            set__CurrentAreaNo_method:call(VillageAreaManager, BUDDY_PLAZA);
                            Owl_supply_method:call(ProgressOwlNestManager);
                            set__CurrentAreaNo_method:call(VillageAreaManager, savedAreaNo);
                        end
                    elseif tempNum == 2 then
                        if savedAreaNo == OUTPOST then
                            Owl_supply_method:call(ProgressOwlNestManager);
                        else
                            set__CurrentAreaNo_method:call(VillageAreaManager, OUTPOST);
                            Owl_supply_method:call(ProgressOwlNestManager);
                            set__CurrentAreaNo_method:call(VillageAreaManager, savedAreaNo);
                        end
                    else
                        if savedAreaNo == BUDDY_PLAZA or savedAreaNo == OUTPOST then
                            Owl_supply_method:call(ProgressOwlNestManager);
                            set__CurrentAreaNo_method:call(VillageAreaManager, savedAreaNo == BUDDY_PLAZA and OUTPOST or BUDDY_PLAZA);
                        else
                            set__CurrentAreaNo_method:call(VillageAreaManager, BUDDY_PLAZA);
                            Owl_supply_method:call(ProgressOwlNestManager);
                            set__CurrentAreaNo_method:call(VillageAreaManager, OUTPOST);
                        end
                        Owl_supply_method:call(ProgressOwlNestManager);
                        set__CurrentAreaNo_method:call(VillageAreaManager, savedAreaNo);
                    end
                end
            end
        end
    end
end

return this;