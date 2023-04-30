local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
local sdk_to_managed_object = sdk.to_managed_object;
local sdk_to_int64 = sdk.to_int64;
local sdk_hook = sdk.hook;
local sdk_CALL_ORIGINAL = sdk.PreHookResult.CALL_ORIGINAL;

local re = re;
local re_on_frame = re.on_frame;

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

local table = table;
local table_insert = table.insert;

local math = math;
local math_min = math.min;
local math_max = math.max;

local string = string;
local string_find = string.find;
local string_format = string.format;

local pairs = pairs;
local tostring = tostring;
------
local KOREAN_GLYPH_RANGES = {
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
};
local font = imgui_load_font("NotoSansKR-Bold.otf", 22, KOREAN_GLYPH_RANGES);
------
local GetPartName_method = sdk_find_type_definition("via.gui.message"):get_method("get(System.Guid, via.Language)");
local GetMonsterName_method = sdk_find_type_definition("snow.gui.MessageManager"):get_method("getEnemyNameMessage(snow.enemy.EnemyDef.EmTypes)");
local isBoss_method = sdk_find_type_definition("snow.enemy.EnemyDef"):get_method("isBoss(snow.enemy.EnemyDef.EmTypes)");

local GameStatusType_Village = sdk_find_type_definition("snow.SnowGameManager.StatusType"):get_field("Village"):get_data(nil);
--
local QuestManager_type_def = sdk_find_type_definition("snow.QuestManager");
local getStatus_method = QuestManager_type_def:get_method("getStatus");
local getQuestTargetTotalBossEmNum_method = QuestManager_type_def:get_method("getQuestTargetTotalBossEmNum");
local getQuestTargetEmTypeList_method = QuestManager_type_def:get_method("getQuestTargetEmTypeList");
local questActivate_method = QuestManager_type_def:get_method("questActivate(snow.LobbyManager.QuestIdentifier)");
local questCancel_method = QuestManager_type_def:get_method("questCancel");
local onChangedGameStatus_method = QuestManager_type_def:get_method("onChangedGameStatus(snow.SnowGameManager.StatusType)");

local QuestTargetEmTypeList_type_def = getQuestTargetEmTypeList_method:get_return_type();
local QuestTargetEmTypeList_get_Count_method = QuestTargetEmTypeList_type_def:get_method("get_Count");
local QuestTargetEmTypeList_get_Item_method = QuestTargetEmTypeList_type_def:get_method("get_Item(System.Int32)");

local QuestStatus_None = getStatus_method:get_return_type():get_field("None"):get_data(nil);
--
local get_RefTargetCameraManager_method = sdk_find_type_definition("snow.CameraManager"):get_method("get_RefTargetCameraManager");

local GetTargetCameraType_method = get_RefTargetCameraManager_method:get_return_type():get_method("GetTargetCameraType");

local TargetCameraType_Marionette = GetTargetCameraType_method:get_return_type():get_field("Marionette"):get_data(nil);

local UpdateTargetCameraParamData_method = sdk_find_type_definition("snow.camera.TargetCamera_Moment"):get_method("UpdateTargetCameraParamData(snow.enemy.EnemyCharacterBase, System.Boolean)");

local EnemyCharacterBase_type_def = sdk_find_type_definition("snow.enemy.EnemyCharacterBase");
local get_EnemyType_method = EnemyCharacterBase_type_def:get_method("get_EnemyType");
--
local GuiManager_type_def = sdk_find_type_definition("snow.gui.GuiManager");
local get_refMonsterList_method = GuiManager_type_def:get_method("get_refMonsterList");
local monsterListParam_field = GuiManager_type_def:get_field("monsterListParam");

local MonsterList_type_def = get_refMonsterList_method:get_return_type();
local getMonsterPartName_method = MonsterList_type_def:get_method("getMonsterPartName(snow.data.monsterList.PartType)");
local MonsterBossData_field = MonsterList_type_def:get_field("_MonsterBossData");

local getEnemyMeatData_method = monsterListParam_field:get_type():get_method("getEnemyMeatData(snow.enemy.EnemyDef.EmTypes)");

local getMeatValue_method = getEnemyMeatData_method:get_return_type():get_method("getMeatValue(snow.enemy.EnemyDef.Meat, System.UInt32, snow.enemy.EnemyDef.MeatAttr)");

local DataList_field = MonsterBossData_field:get_type():get_field("_DataList");

local DataList_type_def = DataList_field:get_type();
local DataList_get_Count_method = DataList_type_def:get_method("get_Count");
local DataList_get_Item_method = DataList_type_def:get_method("get_Item(System.Int32)");

local BossMonsterData_type_def = DataList_get_Item_method:get_return_type();
local getPartTableDataNum_method = BossMonsterData_type_def:get_method("getPartTableDataNum");
local EmType_field = BossMonsterData_type_def:get_field("_EmType");
local PartTableData_field = BossMonsterData_type_def:get_field("_PartTableData");

local PartTableData_type_def = PartTableData_field:get_type();
local PartTableData_get_Item_method = PartTableData_type_def:get_method("get_Item(System.Int32)");

local PartData_type_def = PartTableData_get_Item_method:get_return_type();
local Part_field = PartData_type_def:get_field("_Part");
local EmPart_field = PartData_type_def:get_field("_EmPart");
local EmMeatGroupIdx_field = PartData_type_def:get_field("_EmMeatGroupIdx");
--
local EquipDataManager_type_def = sdk_find_type_definition("snow.data.EquipDataManager");
local getEquippingLvBuffcageData_method = EquipDataManager_type_def:get_method("getEquippingLvBuffcageData");
local calcLvBuffNumToMax_method = EquipDataManager_type_def:get_method("calcLvBuffNumToMax(snow.player.PlayerDefine.LvBuff)");
local calcLvBuffValue_method = EquipDataManager_type_def:get_method("calcLvBuffValue(snow.data.NormalLvBuffCageData.BuffTypes)");

local EquippingLvBuffcageData_type_def = getEquippingLvBuffcageData_method:get_return_type();
local getStatusBuffLimit_method = EquippingLvBuffcageData_type_def:get_method("getStatusBuffLimit(snow.data.NormalLvBuffCageData.BuffTypes)");
local getStatusBuffAddVal_method = EquippingLvBuffcageData_type_def:get_method("getStatusBuffAddVal(snow.data.NormalLvBuffCageData.BuffTypes)");

local PlayerManager_type_def = sdk_find_type_definition("snow.player.PlayerManager");
local addLvBuffCnt_method = PlayerManager_type_def:get_method("addLvBuffCnt(System.Int32, snow.player.PlayerDefine.LvBuff)");
local getLvBuffCnt_method = PlayerManager_type_def:get_method("getLvBuffCnt(snow.player.PlayerDefine.LvBuff)");

local PlayerBase_type_def = sdk_find_type_definition("snow.player.PlayerBase");
local get_PlayerData_method = PlayerBase_type_def:get_method("get_PlayerData");
local get_PlayerSkillList_method = PlayerBase_type_def:get_method("get_PlayerSkillList");

local SpiribirdsCallTimer_field = get_PlayerData_method:get_return_type():get_field("_EquipSkill211_Timer");

local getSkillData_method = get_PlayerSkillList_method:get_return_type():get_method("getSkillData(snow.data.DataDef.PlEquipSkillId)");

local PlayerQuestBase_type_def = sdk_find_type_definition("snow.player.PlayerQuestBase");
local start_method = PlayerQuestBase_type_def:get_method("start");
local onDestroy_method = PlayerQuestBase_type_def:get_method("onDestroy");
local subLvBuffFromEnemy_method = PlayerQuestBase_type_def:get_method("subLvBuffFromEnemy(snow.player.PlayerDefine.LvBuff, System.Int32)");
local updateEquipSkill211_method = PlayerQuestBase_type_def:get_method("updateEquipSkill211");
local get_IsInTrainingArea_method = PlayerQuestBase_type_def:get_method("get_IsInTrainingArea");
local IsEnableStage_Skill211_field = PlayerQuestBase_type_def:get_field("_IsEnableStage_Skill211");

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

local SpiribirdsCall_SkillId = sdk_find_type_definition("snow.data.DataDef.PlEquipSkillId"):get_field("Pl_EquipSkill_211"):get_data(nil);
--
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

local via_Language_Korean = sdk_find_type_definition("via.Language"):get_field("Korean"):get_data(nil);

local LocalizedMeatAttr = {
    [1] = "절단",
    [2] = "타격",
    [3] = "탄",
    [4] = "불",
    [5] = "물",
    [6] = "얼음",
    [7] = "번개",
    [8] = "용"
};


--==--==--==--==--==--


local MonsterListData = nil;
local DataListCreated = false;
local creating = false;

local currentQuestMonsterTypes = nil;
local MonsterHudDataCreated = false;

local function CreateDataList()
    creating = true;
    local GuiManager = sdk_get_managed_singleton("snow.gui.GuiManager");
    if GuiManager then
        local MonsterList = get_refMonsterList_method:call(GuiManager);
        if MonsterList then
            local MonsterBossData = MonsterBossData_field:get_data(MonsterList);
            if MonsterBossData then
                local DataList = DataList_field:get_data(MonsterBossData);
                if DataList then
                    local count = DataList_get_Count_method:call(DataList);
                    if count > 0 then
                        for i = 0, count - 1, 1 do
                            local monster = DataList_get_Item_method:call(DataList, i);
                            if monster then
                                local partTableData_count = getPartTableDataNum_method:call(monster);
                                if partTableData_count > 0 then
                                    local monsterType = EmType_field:get_data(monster);
                                    if monsterType then
                                        local monsterListParam = monsterListParam_field:get_data(GuiManager);
                                        if monsterListParam then
                                            local meatData = getEnemyMeatData_method:call(monsterListParam, monsterType);
                                            local partTableData = PartTableData_field:get_data(monster);
                                            if meatData and partTableData then
                                                local MonsterDataTable = {
                                                    Name = GetMonsterName_method:call(nil, monsterType),
                                                    PartData = {}
                                                };

                                                for i = 0, partTableData_count - 1, 1 do
                                                    local part = PartTableData_get_Item_method:call(partTableData, i);
                                                    if part then
                                                        local partType = Part_field:get_data(part);
                                                        local meatType = EmPart_field:get_data(part);
                                                        if partType and meatType then
                                                            local partGuid = getMonsterPartName_method:call(MonsterList, partType);
                                                            if partGuid then
                                                                local PartDataTable = {
                                                                    PartType    = partType,
                                                                    PartName    = GetPartName_method:call(nil, partGuid, via_Language_Korean),
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
                        DataListCreated = true;
                    end
                end
            end
        end
    end
    creating = false;
end

local function TerminateMonsterHud()
    MonsterHudDataCreated = false;
    currentQuestMonsterTypes = nil;
end

local TargetEnemy = nil;
sdk_hook(UpdateTargetCameraParamData_method, function(args)
    TargetEnemy = sdk_to_managed_object(args[3]);
    if not creating and not DataListCreated then
        CreateDataList();
    end
    return sdk_CALL_ORIGINAL;
end, function()
    if not TargetEnemy then
        TerminateMonsterHud();
    else
        local CameraManager = sdk_get_managed_singleton("snow.CameraManager");
        if CameraManager then
            local TargetCameraManager = get_RefTargetCameraManager_method:call(CameraManager);
            if TargetCameraManager and GetTargetCameraType_method:call(TargetCameraManager) ~= TargetCameraType_Marionette then
                local EnemyType = get_EnemyType_method:call(TargetEnemy);
                if EnemyType then
                    currentQuestMonsterTypes = {EnemyType};
                    MonsterHudDataCreated = true;
                else
                    TerminateMonsterHud();
                end
            end
        end
    end
    TargetEnemy = nil;
end);

local QuestManager = nil;
sdk_hook(questActivate_method, function(args)
    QuestManager = sdk_to_managed_object(args[2]);
    TerminateMonsterHud();
    if not creating and not DataListCreated then
        CreateDataList();
    end
    return sdk_CALL_ORIGINAL;
end, function()
    if getStatus_method:call(QuestManager) == QuestStatus_None and getQuestTargetTotalBossEmNum_method:call(QuestManager) > 0 then
        local QuestTargetEmTypeList = getQuestTargetEmTypeList_method:call(QuestManager);
        if QuestTargetEmTypeList then
            local listCount = QuestTargetEmTypeList_get_Count_method:call(QuestTargetEmTypeList);
            if listCount > 0 then
                for i = 0, listCount - 1, 1 do
                    local QuestTargetEmType = QuestTargetEmTypeList_get_Item_method:call(QuestTargetEmTypeList, i);
                    if isBoss_method:call(nil, QuestTargetEmType) then
                        if not currentQuestMonsterTypes then
                            currentQuestMonsterTypes = {};
                        end
                        table_insert(currentQuestMonsterTypes, QuestTargetEmType);
                        MonsterHudDataCreated = true;
                    end
                end
            end
        end
    end
    QuestManager = nil;
end);

sdk_hook(questCancel_method, nil, TerminateMonsterHud);


--==--==--==--==--==--


local TimerString = {
    Disabled = "향응 비활성 지역",
    Enabled = "향응 타이머: %.2f초"
};

local StatusBuffAddValues = nil;
local StatusBuffLimits = nil;
local AcquiredValues = nil;
local BirdsMaxCounts = nil;
local AcquiredCounts = nil;
local hasRainbow = false;

local isEnable_SpiribirdsCall = false;

local SpiribirdsCall_Timer = nil;
local SpiribirdsHudDataCreated = false;

local PlayerManager = nil;

local addBuffType = nil;
local subBuffType = nil;

local function TerminateSpiribirdsHud()
    SpiribirdsHudDataCreated = false;
    StatusBuffAddValues = nil;
    StatusBuffLimits = nil;
    AcquiredValues = nil;
    BirdsMaxCounts = nil;
    AcquiredCounts = nil;
    hasRainbow = false;
    SpiribirdsCall_Timer = nil;
    isEnable_SpiribirdsCall = false;
end

local function getCountsAndValues(pm, edm, buffType)
    for k, v in pairs(LvBuff) do
        if buffType == v then
            AcquiredCounts[k] = math_min(math_max(getLvBuffCnt_method:call(pm, v), 0), BirdsMaxCounts[k]);
            AcquiredValues[k] = math_min(math_max(calcLvBuffValue_method:call(edm, BuffTypes[k]), 0), StatusBuffLimits[k]);
            break;
        end
    end
end

local start_PlayerQuestBase = nil;
sdk_hook(start_method, function(args)
    start_PlayerQuestBase = sdk_to_managed_object(args[2]);
    isEnable_SpiribirdsCall = false;
    return sdk_CALL_ORIGINAL;
end, function()
    local EquipDataManager = sdk_get_managed_singleton("snow.data.EquipDataManager");
    if EquipDataManager then
        BirdsMaxCounts = {};
        local EquippingLvBuffcageData = getEquippingLvBuffcageData_method:call(EquipDataManager);
        if EquippingLvBuffcageData then
            StatusBuffLimits = {};
            StatusBuffAddValues = {};
            AcquiredValues = {};
            local PlayerManager = sdk_get_managed_singleton("snow.player.PlayerManager");
            if PlayerManager then
                AcquiredCounts = {};
                hasRainbow = getLvBuffCnt_method:call(PlayerManager, LvBuff.Rainbow) > 0;
                for k, v in pairs(LvBuff) do
                    if k ~= "Rainbow" then
                        StatusBuffLimits[k] = getStatusBuffLimit_method:call(EquippingLvBuffcageData, BuffTypes[k]);
                        StatusBuffAddValues[k] = getStatusBuffAddVal_method:call(EquippingLvBuffcageData, BuffTypes[k]);
                        BirdsMaxCounts[k] = calcLvBuffNumToMax_method:call(EquipDataManager, v);
                        if hasRainbow then
                            AcquiredCounts[k] = BirdsMaxCounts[k];
                            AcquiredValues[k] = StatusBuffLimits[k];
                        else
                            AcquiredCounts[k] = math_min(math_max(getLvBuffCnt_method:call(PlayerManager, v), 0), BirdsMaxCounts[k]);
                            AcquiredValues[k] = math_min(math_max(calcLvBuffValue_method:call(EquipDataManager, BuffTypes[k]), 0), StatusBuffLimits[k]);
                        end
                    end
                end
                SpiribirdsHudDataCreated = true;
            end
        end
    end

    if start_PlayerQuestBase then
        if get_IsInTrainingArea_method:call(start_PlayerQuestBase) or not IsEnableStage_Skill211_field:get_data(start_PlayerQuestBase) then
            SpiribirdsCall_Timer = TimerString.Disabled;
        else
            local masterPlayerSkillList = get_PlayerSkillList_method:call(start_PlayerQuestBase);
            if masterPlayerSkillList then
                local SpiribirdsCall_Data = getSkillData_method:call(masterPlayerSkillList, SpiribirdsCall_SkillId);
                if SpiribirdsCall_Data then
                    isEnable_SpiribirdsCall = true;
                end
            end
        end
    end
    start_PlayerQuestBase = nil;
end);

sdk_hook(subLvBuffFromEnemy_method, function(args)
    if SpiribirdsHudDataCreated then
        subBuffType = sdk_to_int64(args[3]) & 0xFF;
    end
    return sdk_CALL_ORIGINAL;
end, function(retval)
    if (sdk_to_int64(retval) & 1) == 1 then
        if subBuffType == LvBuff.Rainbow then
            hasRainbow = false;
            for k, v in pairs(LvBuff) do
                AcquiredCounts[k] = 0;
                AcquiredValues[k] = 0;
            end
        else
            local PlayerManager = sdk_get_managed_singleton("snow.player.PlayerManager");
            local EquipDataManager = sdk_get_managed_singleton("snow.data.EquipDataManager");
            if PlayerManager and EquipDataManager then
                getCountsAndValues(PlayerManager, EquipDataManager, subBuffType);
            end
        end
    end
    subBuffType = nil;
    return retval;
end);

sdk_hook(addLvBuffCnt_method, function(args)
    if SpiribirdsHudDataCreated then
        addBuffType = sdk_to_int64(args[4]) & 0xFFFFFFFF;
        if addBuffType ~= LvBuff.Rainbow then
            PlayerManager = sdk_to_managed_object(args[2]);
        end
    end
    return sdk_CALL_ORIGINAL;
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
        if PlayerManager then
            local EquipDataManager = sdk_get_managed_singleton("snow.data.EquipDataManager");
            if EquipDataManager then
                getCountsAndValues(PlayerManager, EquipDataManager, addBuffType);
            end
        end
    end
    addBuffType = nil;
    PlayerManager = nil;
end);

local PlayerQuestBase = nil;
sdk_hook(updateEquipSkill211_method, function(args)
    if isEnable_SpiribirdsCall then
        PlayerQuestBase = sdk_to_managed_object(args[2]);
    end
    return sdk_CALL_ORIGINAL;
end, function()
    if PlayerQuestBase then
        local masterPlayerData = get_PlayerData_method:call(PlayerQuestBase);
        if masterPlayerData then
            SpiribirdsCall_Timer = string_format(TimerString.Enabled, (3600.0 - SpiribirdsCallTimer_field:get_data(masterPlayerData)) / 60.0);
        end
    end
    PlayerQuestBase = nil;
end);

sdk_hook(onDestroy_method, nil, TerminateSpiribirdsHud);


--==--==--==--==--==--


local GameStatus = nil;
sdk_hook(onChangedGameStatus_method, function(args)
    GameStatus = sdk_to_int64(args[3]) & 0xFFFFFFFF;
    return sdk_CALL_ORIGINAL;
end, function()
    if GameStatus ~= GameStatusType_Village then
        TerminateMonsterHud();
    end
    GameStatus = nil;
end);


--==--==--==--==--==--


local function testAttribute(attribute, value, highest)
    imgui_table_next_column();
    if string_find(highest, attribute) then
        imgui_text_colored(value, 4278190335);
    else
        imgui_text_colored(value, 4294901760);
    end
end

local function buildLvBuffStatusTable()
    if imgui_begin_table("종류", 3, 1 << 21, 25) then
        imgui_table_setup_column("유형", 1 << 3, 25);
        imgui_table_setup_column("횟수", 1 << 3, 20);
        imgui_table_setup_column("수치", 1 << 3, 25);
        
        imgui_table_headers_row();

        imgui_table_next_row();
        imgui_table_next_column();
        imgui_text_colored("공격력: ", 4278190335);
        imgui_table_next_column();
        imgui_text(tostring(AcquiredCounts.Atk) .. "/" .. tostring(BirdsMaxCounts.Atk));
        imgui_table_next_column();
        imgui_text(tostring(AcquiredValues.Atk) .. "/" .. tostring(StatusBuffLimits.Atk));

        imgui_table_next_row();
        imgui_table_next_column();
        imgui_text_colored("방어력: ", 4278222847);
        imgui_table_next_column();
        imgui_text(tostring(AcquiredCounts.Def) .. "/" .. tostring(BirdsMaxCounts.Def));
        imgui_table_next_column();
        imgui_text(tostring(AcquiredValues.Def) .. "/" .. tostring(StatusBuffLimits.Def));

        imgui_table_next_row();
        imgui_table_next_column();
        imgui_text_colored("체력: ", 4278222848);
        imgui_table_next_column();
        imgui_text(tostring(AcquiredCounts.Vital) .. "/" .. tostring(BirdsMaxCounts.Vital));
        imgui_table_next_column();
        imgui_text(tostring(AcquiredValues.Vital) .. "/" .. tostring(StatusBuffLimits.Vital));

        imgui_table_next_row();
        imgui_table_next_column();
        imgui_text_colored("스태미나: ", 4278255615);
        imgui_table_next_column();
        imgui_text(tostring(AcquiredCounts.Stamina) .. "/" .. tostring(BirdsMaxCounts.Stamina));
        imgui_table_next_column();
        imgui_text(tostring(AcquiredValues.Stamina) .. "/" .. tostring(StatusBuffLimits.Stamina));
        imgui_end_table();
    end
end

re_on_frame(function()
    if MonsterHudDataCreated then
        local curQuestTargetMonsterNum = #currentQuestMonsterTypes;
        if curQuestTargetMonsterNum > 0 then
            imgui_push_font(font);
            if imgui_begin_window("몬스터 약점", nil, 4096 + 64 + 512) then
                for i = 1, curQuestTargetMonsterNum, 1 do
                    local curMonsterData = MonsterListData[currentQuestMonsterTypes[i]];
                    if imgui_begin_table("부위", 10, 1 << 21, 25) then
                        imgui_table_setup_column(curMonsterData.Name, 1 << 3, 150);

                        for i = 1, #LocalizedMeatAttr, 1 do
                            imgui_table_setup_column(LocalizedMeatAttr[i], 1 << 3, 25);
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

                    if i < curQuestTargetMonsterNum then
                        imgui_spacing();
                    end
                end
                imgui_pop_font();
                imgui_end_window();
            end
        end
    end

    if SpiribirdsHudDataCreated or SpiribirdsCall_Timer then
        imgui_push_font(font);
        if imgui_begin_window("인혼조", nil, 4096 + 64 + 512) then
            if SpiribirdsHudDataCreated then
                buildLvBuffStatusTable();
                if SpiribirdsCall_Timer then
                    imgui_spacing();
                    imgui_text(SpiribirdsCall_Timer);
                end
            else
                imgui_text(SpiribirdsCall_Timer);
            end
            imgui_pop_font();
            imgui_end_window();
        end
    end
end);