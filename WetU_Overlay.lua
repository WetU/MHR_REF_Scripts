local pairs = pairs;
local tostring = tostring;

local table = table;
local table_insert = table.insert;

local math = math;
local math_min = math.min;
local math_max = math.max;

local string = string;
local string_find = string.find;
local string_format = string.format;

local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
local sdk_to_managed_object = sdk.to_managed_object;
local sdk_to_int64 = sdk.to_int64;
local sdk_hook = sdk.hook;

local re = re;

local imgui = imgui;
local imgui_load_font = imgui.load_font;
local imgui_push_font = imgui.push_font;
local imgui_pop_font = imgui.pop_font;
local imgui_text = imgui.text;
local imgui_text_colored = imgui.text_colored;
local imgui_begin_window = imgui.begin_window;
local imgui_end_window = imgui.end_window;
local imgui_begin_table = imgui.begin_table;
local imgui_table_setup_column = imgui.table_setup_column;
local imgui_table_next_column = imgui.table_next_column;
local imgui_table_headers_row = imgui.table_headers_row;
local imgui_table_next_row = imgui.table_next_row;
local imgui_end_table = imgui.end_table;
local imgui_spacing = imgui.spacing;
------
local font = imgui_load_font("NotoSansKR-Bold.otf", 22, {
    0x0020, 0x00FF, -- Basic Latin + Latin Supplement
    0x2000, 0x206F, -- General Punctuation
    0x3000, 0x30FF, -- CJK Symbols and Punctuations, Hiragana, Katakana
    0x3130, 0x318F, -- Hangul Compatibility Jamo
    0x31F0, 0x31FF, -- Katakana Phonetic Extensions
    0xFF00, 0xFFEF, -- Half-width characters
    0x4e00, 0x9FAF, -- CJK Ideograms
    0xA960, 0xA97F, -- Hangul Jamo Extended-A
    0xAC00, 0xD7A3, -- Hangul Syllables
    0xD7B0, 0xD7FF, -- Hangul Jamo Extended-B
    0
});
------
local GetMonsterName_method = sdk_find_type_definition("snow.gui.MessageManager"):get_method("getEnemyNameMessage(snow.enemy.EnemyDef.EmTypes)"); -- retval

local GameStatusType_Village = sdk_find_type_definition("snow.SnowGameManager.StatusType"):get_field("Village"):get_data(nil);
--
local GuiManager_type_def = sdk_find_type_definition("snow.gui.GuiManager");
local get_refMonsterList_method = GuiManager_type_def:get_method("get_refMonsterList"); -- retval
local monsterListParam_field = GuiManager_type_def:get_field("monsterListParam");

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

local MeatAttr_type_def = sdk_find_type_definition("snow.enemy.EnemyDef.MeatAttr");
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
local QuestManager_type_def = sdk_find_type_definition("snow.QuestManager");
local checkStatus_method = QuestManager_type_def:get_method("checkStatus(snow.QuestManager.Status)"); -- retval
local getQuestTargetTotalBossEmNum_method = QuestManager_type_def:get_method("getQuestTargetTotalBossEmNum"); -- retval
local getQuestTargetEmTypeList_method = QuestManager_type_def:get_method("getQuestTargetEmTypeList"); -- retval

local QuestTargetEmTypeList_type_def = getQuestTargetEmTypeList_method:get_return_type();
local QuestTargetEmTypeList_get_Count_method = QuestTargetEmTypeList_type_def:get_method("get_Count"); -- retval
local QuestTargetEmTypeList_get_Item_method = QuestTargetEmTypeList_type_def:get_method("get_Item(System.Int32)"); -- retval

local QuestStatus_None = sdk_find_type_definition("snow.QuestManager.Status"):get_field("None"):get_data(nil);
--
local EnemyCharacterBase_type_def = sdk_find_type_definition("snow.enemy.EnemyCharacterBase");
local checkDie_method = EnemyCharacterBase_type_def:get_method("checkDie"); -- retval
local get_EnemyType_method = EnemyCharacterBase_type_def:get_method("get_EnemyType"); -- retval
local get_UniqueId_method = EnemyCharacterBase_type_def:get_method("get_UniqueId"); -- retval
--
local EquipDataManager_type_def = sdk_find_type_definition("snow.data.EquipDataManager");
local calcLvBuffNumToMax_method = EquipDataManager_type_def:get_method("calcLvBuffNumToMax(snow.player.PlayerDefine.LvBuff)"); -- retval
local calcLvBuffValue_method = EquipDataManager_type_def:get_method("calcLvBuffValue(snow.data.NormalLvBuffCageData.BuffTypes)"); -- retval
local getEquippingLvBuffcageData_method = EquipDataManager_type_def:get_method("getEquippingLvBuffcageData"); -- retval

local getStatusBuffLimit_method = getEquippingLvBuffcageData_method:get_return_type():get_method("getStatusBuffLimit(snow.data.NormalLvBuffCageData.BuffTypes)"); -- retval

local PlayerManager_type_def = sdk_find_type_definition("snow.player.PlayerManager");
local findMasterPlayer_method = PlayerManager_type_def:get_method("findMasterPlayer"); -- retval
local getLvBuffCnt_method = PlayerManager_type_def:get_method("getLvBuffCnt(snow.player.PlayerDefine.LvBuff)"); -- retval

local PlayerQuestBase_type_def = sdk_find_type_definition("snow.player.PlayerQuestBase");
local get_IsInTrainingArea_method = PlayerQuestBase_type_def:get_method("get_IsInTrainingArea"); -- retval
local IsEnableStage_Skill211_field = PlayerQuestBase_type_def:get_field("_IsEnableStage_Skill211");

local PlayerBase_type_def = findMasterPlayer_method:get_return_type();
local isMasterPlayer_method = PlayerBase_type_def:get_method("isMasterPlayer"); -- retval
local getPlayerIndex_method = PlayerBase_type_def:get_method("getPlayerIndex"); -- retval
local get_PlayerData_method = PlayerBase_type_def:get_method("get_PlayerData"); -- retval

local SpiribirdsCallTimer_field = get_PlayerData_method:get_return_type():get_field("_EquipSkill211_Timer");

local LvBuff_type_def = sdk_find_type_definition("snow.player.PlayerDefine.LvBuff");
local LvBuff = {
    ["Atk"] = LvBuff_type_def:get_field("Attack"):get_data(nil),
    ["Def"] = LvBuff_type_def:get_field("Defence"):get_data(nil),
    ["Vital"] = LvBuff_type_def:get_field("Vital"):get_data(nil),
    ["Stamina"] = LvBuff_type_def:get_field("Stamina"):get_data(nil),
    ["Rainbow"] = LvBuff_type_def:get_field("Rainbow"):get_data(nil)
};

local NormalLvBuffCageData_BuffTypes_type_def = sdk_find_type_definition("snow.data.NormalLvBuffCageData.BuffTypes");
local BuffTypes = {
    ["Atk"] = NormalLvBuffCageData_BuffTypes_type_def:get_field("Atk"):get_data(nil),
    ["Def"] = NormalLvBuffCageData_BuffTypes_type_def:get_field("Def"):get_data(nil),
    ["Vital"] = NormalLvBuffCageData_BuffTypes_type_def:get_field("Vital"):get_data(nil),
    ["Stamina"] = NormalLvBuffCageData_BuffTypes_type_def:get_field("Stamina"):get_data(nil)
};
--
local LongSwordShell010_type_def = sdk_find_type_definition("snow.shell.LongSwordShellManager"):get_method("getMaseterLongSwordShell010s(snow.player.PlayerIndex)"):get_return_type():get_method("get_Item(System.Int32)"):get_return_type();
local lifeTimer_field = LongSwordShell010_type_def:get_field("_lifeTimer");
local CircleType_field = LongSwordShell010_type_def:get_field("_CircleType");

local get_OwnerId_method = sdk_find_type_definition("snow.shell.PlayerShellBase"):get_method("get_OwnerId"); -- retval

local CircleType_type_def = CircleType_field:get_type();
local HarvestMoonCircleType = {
    ["Inside"] = CircleType_type_def:get_field("Inside"):get_data(nil),
    ["Outside"] = CircleType_type_def:get_field("Outside"):get_data(nil)
};
--
local via_Language_Korean = sdk_find_type_definition("via.Language"):get_field("Korean"):get_data(nil);

local MasterPlayerIndex = nil;


--==--==--==--==--==--


local MonsterListData = nil;
local creating = false;

local currentTargetUniqueId = nil;
local currentQuestMonsterTypes = nil;

local function CreateDataList()
    creating = true;
    local GuiManager = sdk_get_managed_singleton("snow.gui.GuiManager");
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
                                            Name = GetMonsterName_method:call(nil, monsterType),
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
                                                            PartName    = sdk.call_native_func(sdk.get_native_singleton("via.gui.message"), sdk_find_type_definition("via.gui.message"), "get(System.Guid, via.Language)", partGuid, via_Language_Korean);
                                                            MeatType    = meatType,
                                                            MeatValues  = {},
                                                            HighestMeat = ""
                                                        };
                                                        for _, attrType in pairs(MeatAttr) do
                                                            for k, v in pairs(attrType) do
                                                                PartDataTable.MeatValues[k] = getMeatValue_method:call(meatData, meatType, EmMeatGroupIdx_field:get_data(part) or 0, v);
                                                            end
                                                        end

                                                        local highestPhys = math_max(PartDataTable.MeatValues.Slash, PartDataTable.MeatValues.Strike, PartDataTable.MeatValues.Shell);
                                                        local highestElem = math_max(PartDataTable.MeatValues.Fire, PartDataTable.MeatValues.Water, PartDataTable.MeatValues.Elect, PartDataTable.MeatValues.Ice, PartDataTable.MeatValues.Dragon);

                                                        for k, v in pairs(PartDataTable.MeatValues) do
                                                            local compareValue = MeatAttr.Phys[k] ~= nil and highestPhys or highestElem;
                                                            if v == compareValue then
                                                                PartDataTable.HighestMeat = PartDataTable.HighestMeat .. "_" .. k;
                                                            end
                                                        end
                                                        table_insert(MonsterDataTable.PartData, PartDataTable);
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

                                            MonsterDataTable.ConditionData.HighestCondition = math_max(
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

                                        if not MonsterListData then
                                            MonsterListData = {};
                                        end
                                        MonsterListData[monsterType] = MonsterDataTable;
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
    currentQuestMonsterTypes = nil;
    currentTargetUniqueId = nil;
end

local TargetEnemyCharacterBase = nil;
sdk_hook(sdk_find_type_definition("snow.camera.TargetCamera_Moment"):get_method("UpdateTargetCameraParamData(snow.enemy.EnemyCharacterBase, System.Boolean)"), function(args)
    if not creating and not MonsterListData then
        CreateDataList();
    end
    TargetEnemyCharacterBase = sdk_to_managed_object(args[3]);
end, function()
    if not TargetEnemyCharacterBase or checkDie_method:call(TargetEnemyCharacterBase) then
        TerminateMonsterHud();
    else
        local EnemyType = get_EnemyType_method:call(TargetEnemyCharacterBase);
        if EnemyType ~= nil and MonsterListData[EnemyType] ~= nil then
            currentTargetUniqueId = get_UniqueId_method:call(TargetEnemyCharacterBase);
            currentQuestMonsterTypes = {EnemyType};
        else
            TerminateMonsterHud();
        end
    end
end);

local EnemyCharacterBase = nil;
sdk_hook(QuestManager_type_def:get_method("questEnemyDie(snow.enemy.EnemyCharacterBase, snow.quest.EmEndType)"), function(args)
    if currentQuestMonsterTypes ~= nil and currentTargetUniqueId ~= nil then
        EnemyCharacterBase = sdk_to_managed_object(args[3]);
    end
end, function()
    if EnemyCharacterBase and get_EnemyType_method:call(EnemyCharacterBase) == currentQuestMonsterTypes[1] and get_UniqueId_method:call(EnemyCharacterBase) == currentTargetUniqueId then
        TerminateMonsterHud();
    end
    EnemyCharacterBase = nil;
end);

local QuestManager = nil;
sdk_hook(QuestManager_type_def:get_method("questActivate(snow.LobbyManager.QuestIdentifier)"), function(args)
    if not creating and not MonsterListData then
        CreateDataList();
    end
    TerminateMonsterHud();
    QuestManager = sdk_to_managed_object(args[2]);
end, function()
    if QuestManager and checkStatus_method:call(QuestManager, QuestStatus_None) and getQuestTargetTotalBossEmNum_method:call(QuestManager) > 0 then
        local QuestTargetEmTypeList = getQuestTargetEmTypeList_method:call(QuestManager);
        if QuestTargetEmTypeList then
            local listCount = QuestTargetEmTypeList_get_Count_method:call(QuestTargetEmTypeList);
            if listCount > 0 then
                for i = 0, listCount - 1, 1 do
                    local QuestTargetEmType = QuestTargetEmTypeList_get_Item_method:call(QuestTargetEmTypeList, i);
                    if QuestTargetEmType ~= nil and MonsterListData[QuestTargetEmType] ~= nil then
                        if not currentQuestMonsterTypes then
                            currentQuestMonsterTypes = {};
                        end
                        table_insert(currentQuestMonsterTypes, QuestTargetEmType);
                    end
                end
            end
        end
    end
    QuestManager = nil;
end);

sdk_hook(QuestManager_type_def:get_method("questCancel"), nil, TerminateMonsterHud);

local doTerminate = nil;
sdk_hook(QuestManager_type_def:get_method("onChangedGameStatus(snow.SnowGameManager.StatusType)"), function(args)
    if (sdk_to_int64(args[3]) & 0xFFFFFFFF) ~= GameStatusType_Village then
        doTerminate = true;
    end
end, function()
    if doTerminate then
        TerminateMonsterHud();
    end
    doTerminate = nil;
end);


--==--==--==--==--==--


local TimerString = {
    Disabled = "향응 비활성 지역",
    Enabled = "향응 타이머: %.f초"
};

local SpiribirdsHudDataCreated = false;
local StatusBuffLimits = nil;
local AcquiredValues = nil;
local BirdsMaxCounts = nil;
local AcquiredCounts = nil;
local hasRainbow = false;

local firstHook = true;
local skipUpdate = false;

local SpiribirdsCall_Timer = nil;

local function TerminateSpiribirdsHud()
    SpiribirdsHudDataCreated = false;
    StatusBuffLimits = nil;
    AcquiredValues = nil;
    BirdsMaxCounts = nil;
    AcquiredCounts = nil;
    hasRainbow = false;
    firstHook = true;
    skipUpdate = false;
    SpiribirdsCall_Timer = nil;
end

local function getCountsAndValues(playerManager, equipDataManager, buffType)
    for k, v in pairs(LvBuff) do
        if buffType == v then
            AcquiredCounts[k] = math_min(math_max(getLvBuffCnt_method:call(playerManager, v), 0), BirdsMaxCounts[k]);
            AcquiredValues[k] = math_min(math_max(calcLvBuffValue_method:call(equipDataManager, BuffTypes[k]), 0), StatusBuffLimits[k]);
            break;
        end
    end
end

local PlayerQuestBase_start = nil;
sdk_hook(PlayerQuestBase_type_def:get_method("start"), function(args)
    PlayerQuestBase_start = sdk_to_managed_object(args[2]);
end, function()
    if PlayerQuestBase_start and isMasterPlayer_method:call(PlayerQuestBase_start) then
        MasterPlayerIndex = getPlayerIndex_method:call(PlayerQuestBase_start);
        local EquipDataManager = sdk_get_managed_singleton("snow.data.EquipDataManager");
        local PlayerManager = sdk_get_managed_singleton("snow.player.PlayerManager");
        if EquipDataManager and PlayerManager then
            hasRainbow = getLvBuffCnt_method:call(PlayerManager, LvBuff.Rainbow) > 0;
            local EquippingLvBuffcageData = getEquippingLvBuffcageData_method:call(EquipDataManager);
            if EquippingLvBuffcageData then
                StatusBuffLimits = {};
                BirdsMaxCounts = {};
                AcquiredCounts = {};
                AcquiredValues = {};
                for k, v in pairs(LvBuff) do
                    if k ~= "Rainbow" then
                        local StatusBuffLimit = getStatusBuffLimit_method:call(EquippingLvBuffcageData, BuffTypes[k]);
                        local LvBuffNumToMax = calcLvBuffNumToMax_method:call(EquipDataManager, v);

                        StatusBuffLimits[k] = StatusBuffLimit;
                        BirdsMaxCounts[k] = LvBuffNumToMax;
                        AcquiredCounts[k] = hasRainbow and LvBuffNumToMax or math_min(math_max(getLvBuffCnt_method:call(PlayerManager, v), 0), LvBuffNumToMax);
                        AcquiredValues[k] = hasRainbow and StatusBuffLimit or math_min(math_max(calcLvBuffValue_method:call(EquipDataManager, BuffTypes[k]), 0), StatusBuffLimit);
                    end
                end
                SpiribirdsHudDataCreated = true;
            end
        end
    end
    PlayerQuestBase_start = nil;
end);

local PlayerQuestBase_subLvBuffFromEnemy = nil;
local subBuffType = nil;
sdk_hook(PlayerQuestBase_type_def:get_method("subLvBuffFromEnemy(snow.player.PlayerDefine.LvBuff, System.Int32)"), function(args)
    if SpiribirdsHudDataCreated then
        PlayerQuestBase_subLvBuffFromEnemy = sdk_to_managed_object(args[2]);
        subBuffType = sdk_to_int64(args[3]) & 0xFFFFFFFF;
    end
end, function(retval)
    if PlayerQuestBase_subLvBuffFromEnemy and isMasterPlayer_method:call(PlayerQuestBase_subLvBuffFromEnemy) and (sdk_to_int64(retval) & 1) == 1 and subBuffType ~= nil then
        if subBuffType == LvBuff.Rainbow then
            hasRainbow = false;
            for k, v in pairs(LvBuff) do
                AcquiredCounts[k] = 0;
                AcquiredValues[k] = 0;
            end
        else
            local EquipDataManager = sdk_get_managed_singleton("snow.data.EquipDataManager");
            local PlayerManager = sdk_get_managed_singleton("snow.player.PlayerManager");
            if EquipDataManager and PlayerManager then
                getCountsAndValues(PlayerManager, EquipDataManager, subBuffType);
            end
        end
    end
    PlayerQuestBase_subLvBuffFromEnemy = nil;
    subBuffType = nil;
    return retval;
end);

local addBuffType = nil;
local PlayerManager_obj = nil;
sdk_hook(PlayerManager_type_def:get_method("addLvBuffCnt(System.Int32, snow.player.PlayerDefine.LvBuff)"), function(args)
    if SpiribirdsHudDataCreated then
        addBuffType = sdk_to_int64(args[4]) & 0xFFFFFFFF;
        if addBuffType ~= nil and addBuffType ~= LvBuff.Rainbow then
            PlayerManager_obj = sdk_to_managed_object(args[2]);
        end
    end
end, function()
    if addBuffType == LvBuff.Rainbow then
        hasRainbow = true;
    end

    if hasRainbow then
        for k, v in pairs(StatusBuffLimits) do
            AcquiredCounts[k] = BirdsMaxCounts[k];
            AcquiredValues[k] = v;
        end
    else
        if PlayerManager_obj then
            local EquipDataManager = sdk_get_managed_singleton("snow.data.EquipDataManager");
            if EquipDataManager then
                getCountsAndValues(PlayerManager_obj, EquipDataManager, addBuffType);
            end
        end
    end
    addBuffType = nil;
    PlayerManager_obj = nil;
end);

local PlayerQuestBase_obj = nil;
sdk_hook(PlayerQuestBase_type_def:get_method("updateEquipSkill211"), function(args)
    if firstHook or not skipUpdate then
        PlayerQuestBase_obj = sdk_to_managed_object(args[2]);
    end
end, function()
    if PlayerQuestBase_obj and isMasterPlayer_method:call(PlayerQuestBase_obj) then
        if firstHook then
            firstHook = false;
            if get_IsInTrainingArea_method:call(PlayerQuestBase_obj) or not IsEnableStage_Skill211_field:get_data(PlayerQuestBase_obj) then
                skipUpdate = true;
                SpiribirdsCall_Timer = TimerString.Disabled;
            else
                local masterPlayerData = get_PlayerData_method:call(PlayerQuestBase_obj);
                if masterPlayerData then
                    local Timer = SpiribirdsCallTimer_field:get_data(masterPlayerData);
                    SpiribirdsCall_Timer = Timer ~= nil and string_format(TimerString.Enabled, 60.0 - (Timer / 60.0)) or nil;
                end
            end
        else
            local masterPlayerData = get_PlayerData_method:call(PlayerQuestBase_obj);
            if masterPlayerData then
                local Timer = SpiribirdsCallTimer_field:get_data(masterPlayerData);
                SpiribirdsCall_Timer = Timer ~= nil and string_format(TimerString.Enabled, 60.0 - (Timer / 60.0)) or nil;
            end
        end
    end
    PlayerQuestBase_obj = nil;
end);


--==--==--==--==--==--


local HarvestMoonTimer_String = {
    ["Inside"] = "원월 내부 타이머: %.f초",
    ["Outside"] = "원월 외부 타이머: %.f초"
};

local HarvestMoonTimer_Inside = nil;
local HarvestMoonTimer_Outside = nil;

local function getMasterPlayerId()
    local PlayerManager = sdk_get_managed_singleton("snow.player.PlayerManager");
    if PlayerManager then
        local masterPlayerBase = findMasterPlayer_method:call(PlayerManager);
        if masterPlayerBase then
            MasterPlayerIndex = getPlayerIndex_method:call(masterPlayerBase);
        end
    end
end

local function getHarvestMoonTimer(shellObj)
    if get_OwnerId_method:call(shellObj) == MasterPlayerIndex then
        local lifeTimer = lifeTimer_field:get_data(shellObj);
        local CircleType = CircleType_field:get_data(shellObj);
        if CircleType == HarvestMoonCircleType.Inside then
            HarvestMoonTimer_Inside = lifeTimer ~= nil and string_format(HarvestMoonTimer_String.Inside, lifeTimer) or nil;
        end
        if CircleType == HarvestMoonCircleType.Outside then
            HarvestMoonTimer_Outside = lifeTimer ~= nil and string_format(HarvestMoonTimer_String.Outside, lifeTimer) or nil;
        end
    end
end

local newPlayerIndex = nil;
sdk_hook(PlayerBase_type_def:get_method("changePlayerIndex(snow.player.PlayerIndex)"), function(args)
    local playerBase = sdk_to_managed_object(args[2]);
    if playerBase and isMasterPlayer_method:call(playerBase) then
        newPlayerIndex = sdk_to_int64(args[3]) & 0xFF;
    end
end, function()
    if newPlayerIndex ~= nil then
        MasterPlayerIndex = newPlayerIndex;
    end
    newPlayerIndex = nil;
end);

local LongSwordShell010_start = nil;
sdk_hook(LongSwordShell010_type_def:get_method("start"), function(args)
    LongSwordShell010_start = sdk_to_managed_object(args[2]);
    if MasterPlayerIndex == nil then
        getMasterPlayerId();
    end
end, function()
    if LongSwordShell010_start then
        getHarvestMoonTimer(LongSwordShell010_start);
    end
    LongSwordShell010_start = nil;
end);

local LongSwordShell010_update = nil;
sdk_hook(LongSwordShell010_type_def:get_method("update"), function(args)
    LongSwordShell010_update = sdk_to_managed_object(args[2]);
    if MasterPlayerIndex == nil then
        getMasterPlayerId();
    end
end, function()
    if LongSwordShell010_update then
        getHarvestMoonTimer(LongSwordShell010_update);
    end
    LongSwordShell010_update = nil;
end);

local LongSwordShell010_onDestroy = nil;
sdk_hook(LongSwordShell010_type_def:get_method("onDestroy"), function(args)
    LongSwordShell010_onDestroy = sdk_to_managed_object(args[2]);
    if MasterPlayerIndex == nil then
        getMasterPlayerId();
    end
    if LongSwordShell010_onDestroy and (get_OwnerId_method:call(LongSwordShell010_onDestroy) ~= MasterPlayerIndex) then
        LongSwordShell010_onDestroy = nil;
    end
end, function()
    if LongSwordShell010_onDestroy then
        local CircleType = CircleType_field:get_data(LongSwordShell010_onDestroy);
        if CircleType == HarvestMoonCircleType.Inside then
            HarvestMoonTimer_Inside = nil;
        end
        if CircleType == HarvestMoonCircleType.Outside then
            HarvestMoonTimer_Outside = nil;
        end
    end
    LongSwordShell010_onDestroy = nil;
end);

sdk_hook(PlayerQuestBase_type_def:get_method("onDestroy"), nil, function()
    TerminateSpiribirdsHud();
    MasterPlayerIndex = nil;
    HarvestMoonTimer_Inside = nil;
    HarvestMoonTimer_Outside = nil;
end);


--==--==--==--==--==--


local LocalizedMeatAttr = {
    "절단",
    "타격",
    "탄",
    "불",
    "물",
    "얼음",
    "번개",
    "용"
};

local LocalizedConditionType = {
    "독",
    "기절",
    "마비",
    "수면",
    "폭파",
    "기력 감소",
    "불",
    "물",
    "번개",
    "얼음"
};

local LocalizedBirdTypes = {
    ["Atk"] = "공격력",
    ["Def"] = "방어력",
    ["Vital"] = "체력",
    ["Stamina"] = "스태미나"
};

local BirdTypeToColor = {
    ["Atk"] = 4278190335,
    ["Def"] = 4278222847,
    ["Vital"] = 4278222848,
    ["Stamina"] = 4278255615
};

local function testAttribute(attribute, value, highest)
    imgui_table_next_column();
    imgui_text_colored(" " .. tostring(value), string_find(highest, attribute) and 4278190335 or 4294901760);
end

local function buildBirdTypeToTable(type)
    imgui_table_next_row();
    imgui_table_next_column();
    imgui_text_colored(LocalizedBirdTypes[type] .. ": ", BirdTypeToColor[type]);
    imgui_table_next_column();
    imgui_text(tostring(AcquiredCounts[type]) .. "/" .. tostring(BirdsMaxCounts[type]));
    imgui_table_next_column();
    imgui_text(tostring(AcquiredValues[type]) .. "/" .. tostring(StatusBuffLimits[type]));
end

re.on_frame(function()
    if currentQuestMonsterTypes then
        imgui_push_font(font);
        if imgui_begin_window("몬스터 약점", nil, 4096 + 64 + 512) then
            local curQuestTargetMonsterNum = #currentQuestMonsterTypes;
            for i = 1, curQuestTargetMonsterNum, 1 do
                local curMonsterData = MonsterListData[currentQuestMonsterTypes[i]];
                if imgui_begin_table("속성", 9, 2097152) then
                    imgui_table_setup_column(curMonsterData.Name, 8, 20.0);

                    for j = 1, #LocalizedMeatAttr, 1 do
                        if (j >= 3 and j <= 5) or j == 8 then
                            imgui_table_setup_column(" " .. LocalizedMeatAttr[j], 8, 3.0);
                        else
                            imgui_table_setup_column(LocalizedMeatAttr[j], 8, 3.0);
                        end
                    end
                    
                    imgui_table_headers_row();

                    for _, part in pairs(curMonsterData.PartData) do
                        imgui_table_next_row();
                        imgui_table_next_column();
                        imgui_text(part.PartName);

                        testAttribute("Slash", part.MeatValues.Slash, part.HighestMeat);
                        testAttribute("Strike", part.MeatValues.Strike, part.HighestMeat);
                        testAttribute("Shell", part.MeatValues.Shell, part.HighestMeat);
                        testAttribute("Fire", part.MeatValues.Fire, part.HighestMeat);
                        testAttribute("Water", part.MeatValues.Water, part.HighestMeat);
                        testAttribute("Ice", part.MeatValues.Ice, part.HighestMeat);
                        testAttribute("Elect", part.MeatValues.Elect, part.HighestMeat);
                        testAttribute("Dragon", part.MeatValues.Dragon, part.HighestMeat);
                    end
                    imgui_end_table();
                end
                if imgui_begin_table("상태 이상", 10, 2097152) then
                    for k = 1, 10, 1 do
                        if k == 6 then
                            imgui_table_setup_column(LocalizedConditionType[k], 8, 5.0);
                        elseif k == 1 or k == 7 or k == 8 then
                            imgui_table_setup_column("   " .. LocalizedConditionType[k], 8, 3.0);
                        else
                            imgui_table_setup_column(" " .. LocalizedConditionType[k], 8, 3.0);
                        end
                    end

                    imgui_table_headers_row();
                    imgui_table_next_row();

                    for m = 1, 10, 1 do
                        local value = curMonsterData.ConditionData[m];
                        imgui_table_next_column();
                        if m == 6 then
                            imgui_text_colored("       " .. tostring(value), value == curMonsterData.ConditionData.HighestCondition and 4278190335 or 4294901760);
                        else
                            imgui_text_colored("    " .. tostring(value), value == curMonsterData.ConditionData.HighestCondition and 4278190335 or 4294901760);
                        end
                    end
                    imgui_end_table();
                end
                if i < curQuestTargetMonsterNum then
                    imgui_spacing();
                end
            end
            imgui_end_window();
        end
        imgui_pop_font();
    end

    if SpiribirdsHudDataCreated or SpiribirdsCall_Timer then
        imgui_push_font(font);
        if imgui_begin_window("인혼조", nil, 4096 + 64 + 512) then
            if SpiribirdsHudDataCreated then
                if imgui_begin_table("종류", 3, 2097152) then
                    imgui_table_setup_column("유형", 8, 25.0);
                    imgui_table_setup_column("횟수", 8, 20.0);
                    imgui_table_setup_column("수치", 8, 25.0);
                    imgui_table_headers_row();
                    buildBirdTypeToTable("Atk");
                    buildBirdTypeToTable("Def");
                    buildBirdTypeToTable("Vital");
                    buildBirdTypeToTable("Stamina");
                    imgui_end_table();
                end
                if SpiribirdsCall_Timer then
                    imgui_spacing();
                    imgui_text(SpiribirdsCall_Timer);
                end
            else
                imgui_text(SpiribirdsCall_Timer);
            end
            imgui_end_window();
        end
        imgui_pop_font();
    end

    if HarvestMoonTimer_Inside or HarvestMoonTimer_Outside then
        imgui_push_font(font);
        if imgui_begin_window("원월", nil, 4096 + 64 + 512) then
            if HarvestMoonTimer_Inside then
                imgui_text(HarvestMoonTimer_Inside);
            end
            if HarvestMoonTimer_Outside then
                imgui_text(HarvestMoonTimer_Outside);
            end
            imgui_end_window();
        end
        imgui_pop_font();
    end
end);