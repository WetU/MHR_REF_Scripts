local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_get_managed_singleton = sdk.get_managed_singleton;

local re = re;
local re_on_frame = re.on_frame;

local imgui = imgui;
local imgui_load_font = imgui.load_font;
local imgui_push_font = imgui.push_font;
local imgui_pop_font = imgui.pop_font;
local imgui_table_next_column = imgui.table_next_column;
local imgui_text = imgui.text;
local imgui_text_colored = imgui.text_colored;
local imgui_begin_window = imgui.begin_window;
local imgui_begin_table = imgui.begin_table;
local imgui_table_setup_column = imgui.table_setup_column;
local imgui_table_headers_row = imgui.table_headers_row;
local imgui_table_next_row = imgui.table_next_row;
local imgui_end_table = imgui.end_table;
local imgui_spacing = imgui.spacing;
local imgui_end_window = imgui.end_window;

local table = table;
local table_insert = table.insert;

local string = string;
local string_find = string.find;

local math = math;
local math_max = math.max;

local pairs = pairs;
--
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
local font = imgui_load_font("NotoSansKR-Bold.otf", 18, KOREAN_GLYPH_RANGES);
--
local GetPartName_method = sdk_find_type_definition("via.gui.message"):get_method("get(System.Guid, via.Language)");
local GetMonsterName_method = sdk_find_type_definition("snow.gui.MessageManager"):get_method("getEnemyNameMessage(snow.enemy.EnemyDef.EmTypes)");
local getMeatValue_method = sdk_find_type_definition("snow.enemy.EnemyMeatData"):get_method("getMeatValue(snow.enemy.EnemyDef.Meat, System.UInt32, snow.enemy.EnemyDef.MeatAttr)");

local QuestManager_type_def = sdk_find_type_definition("snow.QuestManager");
local getQuestTargetEmTypeList_method = QuestManager_type_def:get_method("getQuestTargetEmTypeList");
local getQuestTargetTotalTgtNum_method = QuestManager_type_def:get_method("getQuestTargetTotalTgtNum");
local isActiveQuest_method = QuestManager_type_def:get_method("isActiveQuest");
local QuestStatus_field = QuestManager_type_def:get_field("_QuestStatus");

local QuestTargetEmTypeList_get_Item_method = getQuestTargetEmTypeList_method:get_return_type():get_method("get_Item(System.Int32)");

local GuiManager_type_def = sdk_find_type_definition("snow.gui.GuiManager");
local getEnemyMeatData_method = GuiManager_type_def:get_method("getEnemyMeatData(snow.enemy.EnemyDef.EmTypes)");

local get_refMonsterList_method = GuiManager_type_def:get_method("get_refMonsterList");
local MonsterList_type_def = get_refMonsterList_method:get_return_type();
local getMonsterPartName_method = MonsterList_type_def:get_method("getMonsterPartName(snow.data.monsterList.PartType)");
local MonsterBossData_field = MonsterList_type_def:get_field("_MonsterBossData");

local DataList_field = MonsterBossData_field:get_type():get_field("_DataList");
local DataList_type_def = DataList_field:get_type();
local DataList_get_Count_method = DataList_type_def:get_method("get_Count");
local DataList_get_Item_method = DataList_type_def:get_method("get_Item(System.Int32)");

local BossMonsterData_type_def = sdk_find_type_definition("snow.data.monsterList.BossMonsterData");
local EmType_field = BossMonsterData_type_def:get_field("_EmType");

local PartTableData_field = BossMonsterData_type_def:get_field("_PartTableData");
local PartTableData_type_def = PartTableData_field:get_type();
local PartTableData_get_Count_method = PartTableData_type_def:get_method("get_Count");
local PartTableData_get_Item_method = PartTableData_type_def:get_method("get_Item(System.Int32)");

local PartData_type_def = sdk_find_type_definition("snow.data.monsterList.BossMonsterData.PartData");
local Part_field = PartData_type_def:get_field("_Part");
local EmPart_field = PartData_type_def:get_field("_EmPart");

local MeatAttr = {
    Slash = 0,
    Strike = 1,
    Shell = 2,
    Fire = 3,
    Water = 4,
    Ice = 5,
    Elect = 6,
    Dragon = 7,
    Piyo = 8,
    Max = 9,
    Invalid = 10
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


local MonsterListData = {};
local MonsterListCreated = false;
local creatingList = false;
local function createList()
    creatingList = true;
    local GuiManager = sdk_get_managed_singleton("snow.gui.GuiManager");
    if GuiManager then
        local MonsterList = get_refMonsterList_method:call(GuiManager);
        if MonsterList then
            local MonsterBossData = MonsterBossData_field:get_data(MonsterList);
            if MonsterBossData then
                local DataList = DataList_field:get_data(MonsterBossData);
                if DataList then
                    for i = 0, DataList_get_Count_method:call(DataList) - 1 do
                        local monster = DataList_get_Item_method:call(DataList, i);
                        if monster then
                            local monsterType = EmType_field:get_data(monster);
                            local partData = PartTableData_field:get_data(monster);
                            if monsterType and partData then
                                local meatData = getEnemyMeatData_method:call(GuiManager, monsterType);
                                local MonsterDataTable = {
                                    Type = monsterType,
                                    Name = GetMonsterName_method:call(nil, monsterType),
                                    PartData = {}
                                };
                                if meatData then
                                    for i = 0, PartTableData_get_Count_method:call(partData) - 1 do
                                        local part = PartTableData_get_Item_method:call(partData, i);
                                        if part then
                                            local partType = Part_field:get_data(part);
                                            local meatType = EmPart_field:get_data(part);
                                            if partType and meatType then
                                                local partGuid = getMonsterPartName_method:call(MonsterList, partType);
                                                if partGuid then
                                                    local partName = GetPartName_method:call(nil, partGuid, Language.Korean);
                                                    local PartDataTable = {
                                                        PartType = partType,
                                                        PartName = partName,
                                                        MeatType = meatType,
                                                        Slash    = getMeatValue_method:call(meatData, meatType, 0, MeatAttr.Slash),
                                                        Strike   = getMeatValue_method:call(meatData, meatType, 0, MeatAttr.Strike),
                                                        Shell    = getMeatValue_method:call(meatData, meatType, 0, MeatAttr.Shell),
                                                        Fire     = getMeatValue_method:call(meatData, meatType, 0, MeatAttr.Fire),
                                                        Water    = getMeatValue_method:call(meatData, meatType, 0, MeatAttr.Water),
                                                        Ice      = getMeatValue_method:call(meatData, meatType, 0, MeatAttr.Ice),
                                                        Elect    = getMeatValue_method:call(meatData, meatType, 0, MeatAttr.Elect),
                                                        Dragon   = getMeatValue_method:call(meatData, meatType, 0, MeatAttr.Dragon)
                                                    };
                                                    table_insert(MonsterDataTable.PartData, PartDataTable);
                                                end
                                            end
                                        end
                                    end
                                    MonsterListData[monsterType] = MonsterDataTable;
                                    MonsterListCreated = true;
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    creatingList = false;
end


local function testAttribute(attribute, value, highestPhys, highestElem)
    imgui_table_next_column();
    local isHigh = false;
    if attribute == "Slash" or attribute == "Strike" or attribute == "Shell" then
        if value == highestPhys then
            isHigh = true;
        end
    else
        if value == highestElem then
            isHigh = true;
        end
    end
    if isHigh then
        imgui_text(value);
    else
        imgui_text_colored(value, -65536);
    end
end


--==--==--==--==--==--

local open = false;
local openInitiative = false;
re_on_frame(function()
    if not MonsterListCreated and not creatingList then
        createList();
    else
        local QuestManager = sdk_get_managed_singleton("snow.QuestManager");
        if QuestManager and isActiveQuest_method:call(QuestManager) and QuestStatus_field:get_data(QuestManager) == 0 then
            local targets = getQuestTargetEmTypeList_method:call(QuestManager);
            if targets then
                local target_count = getQuestTargetTotalTgtNum_method:call(QuestManager);
                if target_count ~= 0 then
                    local checkedTargets = "";
                    if openInitiative then
                        open = true;
                    end
                    if open then
                        if font then
                            imgui_push_font(font);
                        end
                        if imgui_begin_window("몬스터 약점", true, 4096 + 64) then
                            for i = 0, target_count - 1 do
                                local target = QuestTargetEmTypeList_get_Item_method:call(targets, i);
                                if target and not string_find(checkedTargets, tostring(target)) then
                                    checkedTargets = checkedTargets .. target .. "_";
                                    local targetData = MonsterListData[target];
                                    if imgui_begin_table("부위", 10, 1 << 21, 25) then
                                        imgui_table_setup_column(targetData.Name, 1 << 3, 125);
                                        imgui_table_setup_column("절단", 1 << 3, 25);
                                        imgui_table_setup_column("타격", 1 << 3, 25);
                                        imgui_table_setup_column("탄", 1 << 3, 25);
                                        imgui_table_setup_column("불", 1 << 3, 25);
                                        imgui_table_setup_column("물", 1 << 3, 25);
                                        imgui_table_setup_column("번개", 1 << 3, 25);
                                        imgui_table_setup_column("얼음", 1 << 3, 25);
                                        imgui_table_setup_column("용", 1 << 3, 25);
                                        imgui_table_headers_row();

                                        for i, part in pairs(targetData.PartData) do
                                            local highestPhys = math_max(part.Slash, part.Strike, part.Shell);
                                            local highestElem = math_max(part.Fire, part.Water, part.Elect, part.Ice, part.Dragon);

                                            imgui_table_next_row();
                                            --imgui.push_id(i)

                                            imgui_table_next_column();
                                            imgui_text(part.PartName);

                                            testAttribute("Slash", part.Slash, highestPhys, highestElem);
                                            testAttribute("Strike", part.Strike, highestPhys, highestElem);
                                            testAttribute("Shell", part.Shell, highestPhys, highestElem);
                                            testAttribute("Fire", part.Fire, highestPhys, highestElem);
                                            testAttribute("Water", part.Water, highestPhys, highestElem);
                                            testAttribute("Elect", part.Elect, highestPhys, highestElem);
                                            testAttribute("Ice", part.Ice, highestPhys, highestElem);
                                            testAttribute("Dragon", part.Dragon, highestPhys, highestElem);
                                            --imgui.pop_id()
                                        end
                                        imgui_end_table();
                                    end
                                end
                                if i < target_count - 1 then
                                    imgui_spacing();
                                end
                            end
                        else
                            open = false;
                        end
                        if font then
                            imgui_pop_font();
                        end
                        imgui_end_window();
                    end
                end
            end
            openInitiative = false;
        else
            openInitiative = true;
        end
    end
end);