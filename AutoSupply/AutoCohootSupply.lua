local require = _G.require;
local Constants = require("Constants.Constants");

local find_type_definition = Constants.sdk.find_type_definition;
local get_managed_singleton = Constants.sdk.get_managed_singleton;
--
local ProgressOwlNestManager_type_def = find_type_definition("snow.progress.ProgressOwlNestManager");
local supply_method = ProgressOwlNestManager_type_def:get_method("supply");
local get_SaveData_method = ProgressOwlNestManager_type_def:get_method("get_SaveData");
local StackItemCount = ProgressOwlNestManager_type_def:get_field("StackItemCount"):get_data(nil);

local ProgressOwlNestSaveData_type_def = get_SaveData_method:get_return_type();
local kamuraStackCount_field = ProgressOwlNestSaveData_type_def:get_field("_StackCount");
local elgadoStackCount_field = ProgressOwlNestSaveData_type_def:get_field("_StackCount2");
--
local VillageAreaManager_type_def = Constants.type_definitions.VillageAreaManager_type_def;
local get__CurrentAreaNo_method = VillageAreaManager_type_def:get_method("get__CurrentAreaNo");
local set__CurrentAreaNo_method = VillageAreaManager_type_def:get_method("set__CurrentAreaNo(snow.stage.StageDef.AreaNoType)");

local AreaNoType_type_def = get__CurrentAreaNo_method:get_return_type();
local BUDDY_PLAZA = AreaNoType_type_def:get_field("No02"):get_data(nil);
local OUTPOST = AreaNoType_type_def:get_field("No06"):get_data(nil);
--
local this = {
    Supply = function()
        local ProgressOwlNestManager = get_managed_singleton("snow.progress.ProgressOwlNestManager");
        local SaveData = get_SaveData_method:call(ProgressOwlNestManager);

        local fullFlag = 0;

        if kamuraStackCount_field:get_data(SaveData) == StackItemCount then
            fullFlag = fullFlag + 1;
        end
        if elgadoStackCount_field:get_data(SaveData) == StackItemCount then
            fullFlag = fullFlag + 2;
        end

        if fullFlag > 0 then
            local VillageAreaManager = get_managed_singleton("snow.VillageAreaManager");
            local savedAreaNo = get__CurrentAreaNo_method:call(VillageAreaManager);

            if fullFlag == 3 then
                if savedAreaNo == BUDDY_PLAZA or savedAreaNo == OUTPOST then
                    supply_method:call(ProgressOwlNestManager);
                    set__CurrentAreaNo_method:call(VillageAreaManager, savedAreaNo == BUDDY_PLAZA and OUTPOST or BUDDY_PLAZA);
                    supply_method:call(ProgressOwlNestManager);
                    set__CurrentAreaNo_method:call(VillageAreaManager, savedAreaNo);
                else
                    set__CurrentAreaNo_method:call(VillageAreaManager, BUDDY_PLAZA);
                    supply_method:call(ProgressOwlNestManager);
                    set__CurrentAreaNo_method:call(VillageAreaManager, OUTPOST);
                    supply_method:call(ProgressOwlNestManager);
                    set__CurrentAreaNo_method:call(VillageAreaManager, savedAreaNo);
                end

            elseif fullFlag == 2 then
                if savedAreaNo == OUTPOST then
                    supply_method:call(ProgressOwlNestManager);
                else
                    set__CurrentAreaNo_method:call(VillageAreaManager, OUTPOST);
                    supply_method:call(ProgressOwlNestManager);
                    set__CurrentAreaNo_method:call(VillageAreaManager, savedAreaNo);
                end

            else
                if savedAreaNo == BUDDY_PLAZA then
                    supply_method:call(ProgressOwlNestManager);
                else
                    set__CurrentAreaNo_method:call(VillageAreaManager, BUDDY_PLAZA);
                    supply_method:call(ProgressOwlNestManager);
                    set__CurrentAreaNo_method:call(VillageAreaManager, savedAreaNo);
                end
            end
        end
    end
};
--
return this;