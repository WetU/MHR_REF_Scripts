local Constants = require("Constants.Constants");
if not Constants then
	return;
end
--
local getEnemyNameMessage_method = Constants.SDK.find_type_definition("snow.gui.MessageManager"):get_method("getEnemyNameMessage(snow.enemy.EnemyDef.EmTypes)"); -- retval
--
local monsterListParam_field = Constants.type_definitions.GuiManager_type_def:get_field("monsterListParam");

local getConditionData_method = monsterListParam_field:get_type():get_method("getConditionData(snow.enemy.EnemyDef.EmTypes)"); -- retval

local Condition_info_field = getConditionData_method:get_return_type():get_field("info");

local Condition_info_get_Item_method = Condition_info_field:get_type():get_method("get_Item(System.Int32)"); -- retval

local effectiveness_field = Condition_info_get_Item_method:get_return_type():get_field("effectiveness");
--
local getQuestTargetTotalBossEmNum_method = Constants.type_definitions.QuestManager_type_def:get_method("getQuestTargetTotalBossEmNum"); -- retval
local getQuestTargetEmTypeList_method = Constants.type_definitions.QuestManager_type_def:get_method("getQuestTargetEmTypeList"); -- retval

local QuestTargetEmTypeList_type_def = getQuestTargetEmTypeList_method:get_return_type();
local QuestTargetEmTypeList_get_Count_method = QuestTargetEmTypeList_type_def:get_method("get_Count"); -- retval
local QuestTargetEmTypeList_get_Item_method = QuestTargetEmTypeList_type_def:get_method("get_Item(System.Int32)"); -- retval
--
local this = {
    EmAilmentData = nil
};
--
function this.TerminateMonsterHud()
    this.EmAilmentData = nil;
end

local QuestManager = nil;
function this.PreHook_questActivate(args)
    this.TerminateMonsterHud();
    QuestManager = Constants.SDK.to_managed_object(args[2]);
end
function this.PostHook_questActivate()
    if QuestManager and Constants.checkQuestStatus(QuestManager, Constants.QuestStatus.None) and getQuestTargetTotalBossEmNum_method:call(QuestManager) > 0 then
        local QuestTargetEmTypeList = getQuestTargetEmTypeList_method:call(QuestManager);
        if QuestTargetEmTypeList then
            local listCount = QuestTargetEmTypeList_get_Count_method:call(QuestTargetEmTypeList);
            if listCount > 0 then
                local GuiManager = Constants.SDK.get_managed_singleton("snow.gui.GuiManager");
                if GuiManager then
                    local monsterListParam = monsterListParam_field:get_data(GuiManager);
                    if monsterListParam then
                        for i = 0, listCount - 1, 1 do
                            local QuestTargetEmType = QuestTargetEmTypeList_get_Item_method:call(QuestTargetEmTypeList, i);
                            if QuestTargetEmType ~= nil then
                                local conditionData = getConditionData_method:call(monsterListParam, QuestTargetEmType);
                                if conditionData then
                                    local MonsterDataTable = {
                                        Name = getEnemyNameMessage_method:call(nil, QuestTargetEmType),
                                        ConditionData = {}
                                    };

                                    local info_array = Condition_info_field:get_data(conditionData);
                                    if info_array then
                                        for j = 0, 9, 1 do
                                            local info = Condition_info_get_Item_method:call(info_array, j);
                                            if info then
                                                local effectiveness = effectiveness_field:get_data(info);
                                                if effectiveness ~= nil then
                                                    MonsterDataTable.ConditionData[j + 1] = effectiveness;
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

                                    if not this.EmAilmentData then
                                        this.EmAilmentData = {};
                                    end
                                    Constants.LUA.table_insert(this.EmAilmentData, MonsterDataTable);
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    QuestManager = nil;
end

return this;