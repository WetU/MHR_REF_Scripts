local Constants = require("Constants.Constants");
if not Constants then
	return;
end
--
local via_Language_Korean = Constants.SDK.find_type_definition("via.Language"):get_field("Korean"):get_data(nil);
local get_PartName_method = Constants.SDK.find_type_definition("via.gui.message"):get_method("get(System.Guid, via.Language)"); -- static
local getEnemyNameMessage_method = Constants.SDK.find_type_definition("snow.gui.MessageManager"):get_method("getEnemyNameMessage(snow.enemy.EnemyDef.EmTypes)"); -- retval

local GameStatusType_Village = Constants.SDK.find_type_definition("snow.SnowGameManager.StatusType"):get_field("Village"):get_data(nil);
--
local get_refMonsterList_method = Constants.type_definitions.GuiManager_type_def:get_method("get_refMonsterList"); -- retval
local monsterListParam_field = Constants.type_definitions.GuiManager_type_def:get_field("monsterListParam");

local MonsterList_type_def = get_refMonsterList_method:get_return_type();
local getMonsterPartName_method = MonsterList_type_def:get_method("getMonsterPartName(snow.data.monsterList.PartType)"); -- static, retval
local MonsterBossData_field = MonsterList_type_def:get_field("_MonsterBossData");

local monsterListParam_type_def = monsterListParam_field:get_type();
local getEnemyMeatData_method = monsterListParam_type_def:get_method("getEnemyMeatData(snow.enemy.EnemyDef.EmTypes)"); -- retval
local getConditionData_method = monsterListParam_type_def:get_method("getConditionData(snow.enemy.EnemyDef.EmTypes)"); -- retval

local getMeatValue_method = getEnemyMeatData_method:get_return_type():get_method("getMeatValue(snow.enemy.EnemyDef.Meat, System.UInt32, snow.enemy.EnemyDef.MeatAttr)"); -- retval

local Condition_info_field = getConditionData_method:get_return_type():get_field("info");

local Condition_info_get_Item_method = Condition_info_field:get_type():get_method("get_Item(System.Int32)"); -- retval

local effectiveness_field = Condition_info_get_Item_method:get_return_type():get_field("effectiveness");

local DataList_field = MonsterBossData_field:get_type():get_field("_DataList");

local DataList_type_def = DataList_field:get_type();
local DataList_get_Count_method = DataList_type_def:get_method("get_Count"); -- retval
local DataList_get_Item_method = DataList_type_def:get_method("get_Item(System.Int32)"); -- retval

local BossMonsterData_type_def = DataList_get_Item_method:get_return_type();
local getPartTableDataNum_method = BossMonsterData_type_def:get_method("getPartTableDataNum"); -- retval
local EmType_field = BossMonsterData_type_def:get_field("_EmType");
local PartTableData_field = BossMonsterData_type_def:get_field("_PartTableData");

local PartTableData_get_Item_method = PartTableData_field:get_type():get_method("get_Item(System.Int32)"); -- retval

local PartData_type_def = PartTableData_get_Item_method:get_return_type();
local Part_field = PartData_type_def:get_field("_Part");
local EmPart_field = PartData_type_def:get_field("_EmPart");
local EmMeatGroupIdx_field = PartData_type_def:get_field("_EmMeatGroupIdx");

local MeatAttr_type_def = Constants.SDK.find_type_definition("snow.enemy.EnemyDef.MeatAttr");
local MeatAttr = {
    ["Phys"] = {
        Slash = MeatAttr_type_def:get_field("Slash"):get_data(nil),
        Strike = MeatAttr_type_def:get_field("Strike"):get_data(nil),
        Shell = MeatAttr_type_def:get_field("Shell"):get_data(nil)
    },
    ["Elem"] = {
        Fire = MeatAttr_type_def:get_field("Fire"):get_data(nil),
        Water = MeatAttr_type_def:get_field("Water"):get_data(nil),
        Ice = MeatAttr_type_def:get_field("Ice"):get_data(nil),
        Elect = MeatAttr_type_def:get_field("Elect"):get_data(nil),
        Dragon = MeatAttr_type_def:get_field("Dragon"):get_data(nil)
    }
};
--
local getQuestTargetTotalBossEmNum_method = Constants.type_definitions.QuestManager_type_def:get_method("getQuestTargetTotalBossEmNum"); -- retval
local getQuestTargetEmTypeList_method = Constants.type_definitions.QuestManager_type_def:get_method("getQuestTargetEmTypeList"); -- retval

local QuestTargetEmTypeList_type_def = getQuestTargetEmTypeList_method:get_return_type();
local QuestTargetEmTypeList_get_Count_method = QuestTargetEmTypeList_type_def:get_method("get_Count"); -- retval
local QuestTargetEmTypeList_get_Item_method = QuestTargetEmTypeList_type_def:get_method("get_Item(System.Int32)"); -- retval
--
local EnemyCharacterBase_type_def = Constants.SDK.find_type_definition("snow.enemy.EnemyCharacterBase");
local checkDie_method = EnemyCharacterBase_type_def:get_method("checkDie"); -- retval
local get_EnemyType_method = EnemyCharacterBase_type_def:get_method("get_EnemyType"); -- retval
local get_UniqueId_method = EnemyCharacterBase_type_def:get_method("get_UniqueId"); -- retval
--
local this = {
    MonsterListData = nil,
    currentQuestMonsterTypes = nil
};
--
local creating = false;
local currentTargetUniqueId = nil;

local function CreateDataList()
    creating = true;
    local GuiManager = Constants.SDK.get_managed_singleton("snow.gui.GuiManager");
    if GuiManager then
        local MonsterList = get_refMonsterList_method:call(GuiManager);
        local monsterListParam = monsterListParam_field:get_data(GuiManager);
        if MonsterList and monsterListParam then
            local MonsterBossData = MonsterBossData_field:get_data(MonsterList);
            if MonsterBossData then
                local DataList = DataList_field:get_data(MonsterBossData);
                if DataList then
                    local count = DataList_get_Count_method:call(DataList);
                    if count > 0 then
                        for i = 0, count - 1, 1 do
                            local monster = DataList_get_Item_method:call(DataList, i);
                            if monster then
                                local monsterType = EmType_field:get_data(monster);
                                local partTableData_count = getPartTableDataNum_method:call(monster);
                                local partTableData = PartTableData_field:get_data(monster);
                                if monsterType and partTableData_count > 0 and partTableData then
                                    local meatData = getEnemyMeatData_method:call(monsterListParam, monsterType);
                                    local conditionData = getConditionData_method:call(monsterListParam, monsterType);
                                    if meatData and conditionData then
                                        local MonsterDataTable = {
                                            Name = getEnemyNameMessage_method:call(nil, monsterType),
                                            PartData = {},
                                            ConditionData = {}
                                        };
                                        for i = 0, partTableData_count - 1, 1 do
                                            local part = PartTableData_get_Item_method:call(partTableData, i);
                                            if part then
                                                local partType = Part_field:get_data(part);
                                                local meatType = EmPart_field:get_data(part);
                                                if partType and meatType then
                                                    local partGuid = getMonsterPartName_method:call(nil, partType);
                                                    if partGuid then
                                                        local PartDataTable = {
                                                            PartType    = partType,
                                                            PartName    = get_PartName_method:call(nil, partGuid, via_Language_Korean);
                                                            MeatType    = meatType,
                                                            MeatValues  = {},
                                                            HighestMeat = ""
                                                        };
                                                        for _, attrType in Constants.LUA.pairs(MeatAttr) do
                                                            for k, v in Constants.LUA.pairs(attrType) do
                                                                PartDataTable.MeatValues[k] = getMeatValue_method:call(meatData, meatType, EmMeatGroupIdx_field:get_data(part) or 0, v);
                                                            end
                                                        end

                                                        local highestPhys = Constants.LUA.math_max(PartDataTable.MeatValues.Slash, PartDataTable.MeatValues.Strike, PartDataTable.MeatValues.Shell);
                                                        local highestElem = Constants.LUA.math_max(PartDataTable.MeatValues.Fire, PartDataTable.MeatValues.Water, PartDataTable.MeatValues.Elect, PartDataTable.MeatValues.Ice, PartDataTable.MeatValues.Dragon);

                                                        for k, v in Constants.LUA.pairs(PartDataTable.MeatValues) do
                                                            local compareValue = MeatAttr.Phys[k] ~= nil and highestPhys or highestElem;
                                                            if v == compareValue then
                                                                PartDataTable.HighestMeat = PartDataTable.HighestMeat .. "_" .. k;
                                                            end
                                                        end
                                                        Constants.LUA.table_insert(MonsterDataTable.PartData, PartDataTable);
                                                    end
                                                end
                                            end
                                        end

                                        local info_array = Condition_info_field:get_data(conditionData);
                                        if info_array then
                                            for i = 0, 9, 1 do
                                                local info = Condition_info_get_Item_method:call(info_array, i);
                                                if info then
                                                    local effectiveness = effectiveness_field:get_data(info);
                                                    if effectiveness ~= nil then
                                                        MonsterDataTable.ConditionData[i + 1] = effectiveness;
                                                    end
                                                end
                                            end

                                            MonsterDataTable.ConditionData.HighestCondition = Constants.LUA.math_max(
                                                MonsterDataTable.ConditionData[1],
                                                MonsterDataTable.ConditionData[2],
                                                MonsterDataTable.ConditionData[3],
                                                MonsterDataTable.ConditionData[4],
                                                MonsterDataTable.ConditionData[5],
                                                MonsterDataTable.ConditionData[6],
                                                MonsterDataTable.ConditionData[7],
                                                MonsterDataTable.ConditionData[8],
                                                MonsterDataTable.ConditionData[9],
                                                MonsterDataTable.ConditionData[10]
                                            );
                                        end

                                        if not this.MonsterListData then
                                            this.MonsterListData = {};
                                        end
                                        this.MonsterListData[monsterType] = MonsterDataTable;
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    creating = false;
end

local function TerminateMonsterHud()
    this.currentQuestMonsterTypes = nil;
    currentTargetUniqueId = nil;
end

local EnemyCharacterBase = nil;
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.camera.TargetCamera_Moment"):get_method("UpdateTargetCameraParamData(snow.enemy.EnemyCharacterBase, System.Boolean)"), function(args)
    if not creating and not this.MonsterListData then
        CreateDataList();
    end
    EnemyCharacterBase = Constants.SDK.to_managed_object(args[3]);
end, function()
    if not EnemyCharacterBase or checkDie_method:call(EnemyCharacterBase) then
        TerminateMonsterHud();
    else
        local EnemyType = get_EnemyType_method:call(EnemyCharacterBase);
        if EnemyType ~= nil and this.MonsterListData[EnemyType] ~= nil then
            currentTargetUniqueId = get_UniqueId_method:call(EnemyCharacterBase);
            this.currentQuestMonsterTypes = {EnemyType};
        else
            TerminateMonsterHud();
        end
    end
    EnemyCharacterBase = nil;
end);

Constants.SDK.hook(Constants.type_definitions.QuestManager_type_def:get_method("questEnemyDie(snow.enemy.EnemyCharacterBase, snow.quest.EmEndType)"), function(args)
    if this.currentQuestMonsterTypes ~= nil and currentTargetUniqueId ~= nil then
        EnemyCharacterBase = Constants.SDK.to_managed_object(args[3]);
    end
end, function()
    if EnemyCharacterBase and get_EnemyType_method:call(EnemyCharacterBase) == this.currentQuestMonsterTypes[1] and get_UniqueId_method:call(EnemyCharacterBase) == currentTargetUniqueId then
        TerminateMonsterHud();
    end
    EnemyCharacterBase = nil;
end);

local QuestManager = nil;
Constants.SDK.hook(Constants.type_definitions.QuestManager_type_def:get_method("questActivate(snow.LobbyManager.QuestIdentifier)"), function(args)
    if not creating and not this.MonsterListData then
        CreateDataList();
    end
    TerminateMonsterHud();
    QuestManager = Constants.SDK.to_managed_object(args[2]);
end, function()
    if QuestManager and Constants.checkStatus_None(QuestManager) and getQuestTargetTotalBossEmNum_method:call(QuestManager) > 0 then
        local QuestTargetEmTypeList = getQuestTargetEmTypeList_method:call(QuestManager);
        if QuestTargetEmTypeList then
            local listCount = QuestTargetEmTypeList_get_Count_method:call(QuestTargetEmTypeList);
            if listCount > 0 then
                for i = 0, listCount - 1, 1 do
                    local QuestTargetEmType = QuestTargetEmTypeList_get_Item_method:call(QuestTargetEmTypeList, i);
                    if QuestTargetEmType ~= nil and this.MonsterListData[QuestTargetEmType] ~= nil then
                        if not this.currentQuestMonsterTypes then
                            this.currentQuestMonsterTypes = {};
                        end
                        Constants.LUA.table_insert(this.currentQuestMonsterTypes, QuestTargetEmType);
                    end
                end
            end
        end
    end
    QuestManager = nil;
end);

Constants.SDK.hook(Constants.type_definitions.QuestManager_type_def:get_method("questCancel"), nil, TerminateMonsterHud);

Constants.SDK.hook(Constants.type_definitions.QuestManager_type_def:get_method("onChangedGameStatus(snow.SnowGameManager.StatusType)"), function(args)
    if (Constants.SDK.to_int64(args[3]) & 0xFFFFFFFF) ~= GameStatusType_Village then
        TerminateMonsterHud();
    end
end);

return this;