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
local imgui_same_line = imgui.same_line;
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
local math_ceil = math.ceil;

local string = string;
local string_find = string.find;

local pairs = pairs;
local type = type;
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

local GameStatusType_type_def = sdk_find_type_definition("snow.SnowGameManager.StatusType");
local GameStatusType = {
    ["Village"] = GameStatusType_type_def:get_field("Village"):get_data(nil),
    ["Quest"] = GameStatusType_type_def:get_field("Quest"):get_data(nil)
};
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
local TargetCameraManager_type_def = sdk_find_type_definition("snow.camera.TargetCameraManager");
local GetTargetCameraType_method = TargetCameraManager_type_def:get_method("GetTargetCameraType");
local GetTargetEnemy_method = TargetCameraManager_type_def:get_method("GetTargetEnemy");

local TargetCameraType_Marionette = GetTargetCameraType_method:get_return_type():get_field("Marionette"):get_data(nil);

local get_EnemyType_method = GetTargetEnemy_method:get_return_type():get_method("get_EnemyType");
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
local EmType_field = BossMonsterData_type_def:get_field("_EmType");
local PartTableData_field = BossMonsterData_type_def:get_field("_PartTableData");

local PartTableData_type_def = PartTableData_field:get_type();
local PartTableData_get_Count_method = PartTableData_type_def:get_method("get_Count");
local PartTableData_get_Item_method = PartTableData_type_def:get_method("get_Item(System.Int32)");

local PartData_type_def = PartTableData_get_Item_method:get_return_type();
local Part_field = PartData_type_def:get_field("_Part");
local EmPart_field = PartData_type_def:get_field("_EmPart");
--
local getEquippingLvBuffcageData_method = sdk_find_type_definition("snow.data.EquipDataManager"):get_method("getEquippingLvBuffcageData");

local NormalLvBuffCageData_type_def = getEquippingLvBuffcageData_method:get_return_type();
local getStatusBuffLimit_method = NormalLvBuffCageData_type_def:get_method("getStatusBuffLimit(snow.data.NormalLvBuffCageData.BuffTypes)");
local getStatusBuffAddVal_method = NormalLvBuffCageData_type_def:get_method("getStatusBuffAddVal(snow.data.NormalLvBuffCageData.BuffTypes)");

local PlayerManager_type_def = sdk_find_type_definition("snow.player.PlayerManager");
local addLvBuffCnt_method = PlayerManager_type_def:get_method("addLvBuffCnt(System.Int32, snow.player.PlayerDefine.LvBuff)");

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

local MeatAttr = {
    ["Phys"] = {
        Slash = 0,
        Strike = 1,
        Shell = 2
    },
    ["Elem"] = {
        Fire = 3,
        Water = 4,
        Ice = 5,
        Elect = 6,
        Dragon = 7
    }
};

local LocalizedMeatAttr = {
    [0] = "절단",
    [1] = "타격",
    [2] = "탄",
    [3] = "불",
    [4] = "물",
    [5] = "얼음",
    [6] = "번개",
    [7] = "용"
};

local Language = {
    Japanese = 0,
    English = 1,
    French = 2,
    Italian = 3,
    German = 4,
    Spanish = 5,
    Russian = 6,
    Polish = 7,
    Dutch = 8,
    Portuguese = 9,
    PortugueseBr = 10,
    Korean = 11,
    TransitionalChinese = 12,
    SimplelifiedChinese = 13,
    Finnish = 14,
    Swedish = 15,
    Danish = 16,
    Norwegian = 17,
    Czech = 18,
    Hungarian = 19,
    Slovak = 20,
    Arabic = 21,
    Turkish = 22,
    Bulgarian = 23,
    Greek = 24,
    Romanian = 25,
    Thai = 26,
    Ukrainian = 27,
    Vietnamese = 28,
    Indonesian = 29,
    Fiction = 30,
    Hindi = 31,
    LatinAmericanSpanish = 32,
    Max = 33,
    Unknown = 33
};


--==--==--==--==--==--


local MonsterListData = nil;
local DataListCreated = false;
local creating = false;

local currentQuestMonsterTypes = nil;
local savedTargetEnemy = nil;
local MonsterHudDataCreated = false;

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
                    local counts = DataList_get_Count_method:call(DataList);
                    if counts > 0 then
                        for i = 0, counts - 1, 1 do
                            local monster = DataList_get_Item_method:call(DataList, i);
                            if monster then
                                local monsterType = EmType_field:get_data(monster);
                                if monsterType then
                                    local meatData = getEnemyMeatData_method:call(monsterListParam, monsterType);
                                    local partTableData = PartTableData_field:get_data(monster);
                                    if meatData and partTableData then
                                        local partTableData_counts = PartTableData_get_Count_method:call(partTableData);
                                        if partTableData_counts > 0 then
                                            local MonsterDataTable = {
                                                Name = GetMonsterName_method:call(nil, monsterType),
                                                PartData = {}
                                            };

                                            for i = 0, partTableData_counts - 1, 1 do
                                                local part = PartTableData_get_Item_method:call(partTableData, i);
                                                if part then
                                                    local partType = Part_field:get_data(part);
                                                    local meatType = EmPart_field:get_data(part);
                                                    if partType and meatType then
                                                        local partGuid = getMonsterPartName_method:call(MonsterList, partType);
                                                        if partGuid then
                                                            local PartDataTable = {
                                                                PartType    = partType,
                                                                PartName    = GetPartName_method:call(nil, partGuid, Language.Korean),
                                                                MeatType    = meatType,
                                                                Slash       = getMeatValue_method:call(meatData, meatType, 0, MeatAttr.Phys.Slash),
                                                                Strike      = getMeatValue_method:call(meatData, meatType, 0, MeatAttr.Phys.Strike),
                                                                Shell       = getMeatValue_method:call(meatData, meatType, 0, MeatAttr.Phys.Shell),
                                                                Fire        = getMeatValue_method:call(meatData, meatType, 0, MeatAttr.Elem.Fire),
                                                                Water       = getMeatValue_method:call(meatData, meatType, 0, MeatAttr.Elem.Water),
                                                                Elect       = getMeatValue_method:call(meatData, meatType, 0, MeatAttr.Elem.Elect),
                                                                Ice         = getMeatValue_method:call(meatData, meatType, 0, MeatAttr.Elem.Ice),
                                                                Dragon      = getMeatValue_method:call(meatData, meatType, 0, MeatAttr.Elem.Dragon),
                                                                highest     = ""
                                                            };

                                                            local highestPhys = math_max(PartDataTable.Slash, PartDataTable.Strike, PartDataTable.Shell);
                                                            local highestElem = math_max(PartDataTable.Fire, PartDataTable.Water, PartDataTable.Elect, PartDataTable.Ice, PartDataTable.Dragon);

                                                            for k in pairs(MeatAttr.Phys) do
                                                                if PartDataTable[k] == highestPhys then
                                                                    PartDataTable.highest = PartDataTable.highest .. "_" .. k;
                                                                end
                                                            end

                                                            for k in pairs(MeatAttr.Elem) do
                                                                if PartDataTable[k] == highestElem then
                                                                    PartDataTable.highest = PartDataTable.highest .. "_" .. k;
                                                                end
                                                            end

                                                            table_insert(MonsterDataTable.PartData, PartDataTable);
                                                        end
                                                    end
                                                end
                                            end

                                            if type(MonsterListData) ~= "table" then
                                                MonsterListData = {};
                                            end
                                            MonsterListData[monsterType] = MonsterDataTable;
                                            DataListCreated = true;
                                        end
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
    MonsterHudDataCreated = false;
    currentQuestMonsterTypes = nil;
end

local TargetCameraManager = nil;
sdk_hook(GetTargetEnemy_method, function(args)
    TargetCameraManager = sdk_to_managed_object(args[2]);
    if not creating and not DataListCreated then
        CreateDataList();
    end
    return sdk_CALL_ORIGINAL;
end, function(retval)
    if TargetCameraManager then
        if retval ~= nil then
            local TargetCameraType = GetTargetCameraType_method:call(TargetCameraManager);
            if TargetCameraType ~= TargetCameraType_Marionette then
                local TargetEnemy = sdk_to_managed_object(retval);
                if TargetEnemy then
                    if savedTargetEnemy ~= TargetEnemy then
                        savedTargetEnemy = TargetEnemy;
                        local EnemyType = get_EnemyType_method:call(TargetEnemy);
                        if EnemyType then
                            currentQuestMonsterTypes = {EnemyType};
                            MonsterHudDataCreated = true;
                        else
                            TerminateMonsterHud();
                        end
                    end
                else
                    TerminateMonsterHud();
                end
            end
        end
        TargetCameraManager = nil;
    end
    return retval;
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
    if QuestManager then
        if getStatus_method:call(QuestManager) == QuestStatus_None and getQuestTargetTotalBossEmNum_method:call(QuestManager) > 0 then
            local QuestTargetEmTypeList = getQuestTargetEmTypeList_method:call(QuestManager);
            if QuestTargetEmTypeList then
                local listCounts = QuestTargetEmTypeList_get_Count_method:call(QuestTargetEmTypeList);
                if listCounts > 0 then
                    for i = 0, listCounts - 1, 1 do
                        local QuestTargetEmType = QuestTargetEmTypeList_get_Item_method:call(QuestTargetEmTypeList, i);
                        if isBoss_method:call(nil, QuestTargetEmType) then
                            if type(currentQuestMonsterTypes) ~= "table" then
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
    end
end);

sdk_hook(questCancel_method, nil, TerminateMonsterHud);


--==--==--==--==--==--


local StatusBuffLimits = nil; -- MaxValues
local StatusBuffAddVal = nil;
local AcquiredCounts = nil;
local AcquiredValues = nil; -- StatusBuffAddVal * AcquiredCounts
local BirdsMaxCounts = nil;

local SpiribirdsHudDataCreated = false;

local function InitSpiribirdsHud(obj)
    StatusBuffLimits = {};
    StatusBuffAddVal = {};
    AcquiredCounts = {};
    AcquiredValues = {};
    BirdsMaxCounts = {};
    for k, v in pairs(BuffTypes) do
        local StatusBuffLimit = getStatusBuffLimit_method:call(obj, v);
        local StatusBuffAddValue = getStatusBuffAddVal_method:call(obj, v);
        StatusBuffLimits[k] = StatusBuffLimit;
        StatusBuffAddVal[k] = StatusBuffAddValue;
        AcquiredCounts[k] = 0;
        AcquiredValues[k] = 0;
        BirdsMaxCounts[k] = math_ceil(StatusBuffLimit / StatusBuffAddValue);
    end
    SpiribirdsHudDataCreated = true;
end

local function TerminateSpiribirdsHud()
    SpiribirdsHudDataCreated = false;
    StatusBuffLimits = nil;
    StatusBuffAddVal = nil;
    AcquiredCounts = nil;
    AcquiredValues = nil;
    BirdsMaxCounts = nil;
end

sdk_hook(addLvBuffCnt_method, function(args)
    local BuffType = sdk_to_int64(args[4]) & 0xFF;
    if BuffType == LvBuff.Rainbow then
        for k, v in pairs(StatusBuffLimits) do
            AcquiredCounts[k] = BirdsMaxCounts[k];
            AcquiredValues[k] = v;
        end
    else
        local count = sdk_to_int64(args[3]) & 0xFFFFFFFF;
        if count > 0 then
            for k, v in pairs(LvBuff) do
                if BuffType == v then
                    local newCount = math_min(AcquiredCounts[k] + count, BirdsMaxCounts[k]);
                    AcquiredCounts[k] = newCount;
                    AcquiredValues[k] = math_min(newCount * StatusBuffAddVal[k], StatusBuffLimits[k]);
                    break;
                end
            end
        end
    end
    return sdk_CALL_ORIGINAL;
end);

sdk_hook(onChangedGameStatus_method, function(args)
    local CurrentStatus = sdk_to_int64(args[3]) & 0xFFFFFFFF;
    if CurrentStatus ~= GameStatusType.Village and CurrentStatus ~= GameStatusType.Quest then
        TerminateMonsterHud();
        TerminateSpiribirdsHud();
    elseif CurrentStatus ~= GameStatusType.Village then
        TerminateMonsterHud();
        if CurrentStatus == GameStatusType.Quest then
            if not StatusBuffLimits or not StatusBuffAddVal then
                local EquipDataManager = sdk_get_managed_singleton("snow.data.EquipDataManager");
                if EquipDataManager then
                    local EquippingLvBuffcageData = getEquippingLvBuffcageData_method:call(EquipDataManager);
                    if EquippingLvBuffcageData then
                        InitSpiribirdsHud(EquippingLvBuffcageData);
                    end
                end
            end
        end
    elseif CurrentStatus ~= GameStatusType.Quest then
        TerminateSpiribirdsHud()
        if CurrentStatus == GameStatusType.Village then
            savedTargetEnemy = nil;
        end
    end
    return sdk_CALL_ORIGINAL;
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
                        for i = 0, #LocalizedMeatAttr, 1 do
                            imgui_table_setup_column(LocalizedMeatAttr[i], 1 << 3, 25);
                        end
                        imgui_table_headers_row();

                        for _, part in pairs(curMonsterData.PartData) do
                            imgui_table_next_row();
                            imgui_table_next_column();
                            imgui_text(part.PartName);

                            testAttribute("Slash", part.Slash, part.highest);
                            testAttribute("Strike", part.Strike, part.highest);
                            testAttribute("Shell", part.Shell, part.highest);
                            testAttribute("Fire", part.Fire, part.highest);
                            testAttribute("Water", part.Water, part.highest);
                            testAttribute("Elect", part.Elect, part.highest);
                            testAttribute("Ice", part.Ice, part.highest);
                            testAttribute("Dragon", part.Dragon, part.highest);
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

    if SpiribirdsHudDataCreated then
        imgui_push_font(font);
        if imgui_begin_window("인혼조", nil, 4096 + 64 + 512) then
            imgui_text_colored("빨간", 4278190335);
            imgui_same_line();
            imgui_text("인혼조: " .. tostring(AcquiredCounts.Atk) .. "/" .. tostring(BirdsMaxCounts.Atk) .. " (" .. tostring(AcquiredValues.Atk) .. "/" .. tostring(StatusBuffLimits.Atk) .. ")");
            imgui_text_colored("주황", 4278222847);
            imgui_same_line();
            imgui_text("인혼조: " .. tostring(AcquiredCounts.Def) .. "/" .. tostring(BirdsMaxCounts.Def) .. " (" .. tostring(AcquiredValues.Def) .. "/" .. tostring(StatusBuffLimits.Def) .. ")");
            imgui_text_colored("초록", 4278222848);
            imgui_same_line();
            imgui_text("인혼조: " .. tostring(AcquiredCounts.Vital) .. "/" .. tostring(BirdsMaxCounts.Vital) .. " (" .. tostring(AcquiredValues.Vital) .. "/" .. tostring(StatusBuffLimits.Vital) .. ")");
            imgui_text_colored("노란", 4278255615);
            imgui_same_line();
            imgui_text("인혼조: " .. tostring(AcquiredCounts.Stamina) .. "/" .. tostring(BirdsMaxCounts.Stamina) .. " (" .. tostring(AcquiredValues.Stamina) .. "/" .. tostring(StatusBuffLimits.Stamina) .. ")");
            imgui_pop_font();
            imgui_end_window();
        end
    end
end);