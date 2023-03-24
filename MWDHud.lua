local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
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
local math_max = math.max;

local string = string;
local string_find = string.find;

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

local QuestManager_type_def = sdk_find_type_definition("snow.QuestManager");
local isActiveQuest_method = QuestManager_type_def:get_method("isActiveQuest");
local getStatus_method = QuestManager_type_def:get_method("getStatus");
local isQuestTargetEnemy_method = QuestManager_type_def:get_method("isQuestTargetEnemy(snow.enemy.EnemyDef.EmTypes, System.Boolean)");
local getQuestTargetTotalBossEmNum_method = QuestManager_type_def:get_method("getQuestTargetTotalBossEmNum");
local questCancel_method = QuestManager_type_def:get_method("questCancel");
local onChangedGameStatus_method = QuestManager_type_def:get_method("onChangedGameStatus(snow.SnowGameManager.StatusType)");

local GuiManager_type_def = sdk_find_type_definition("snow.gui.GuiManager");
local isQuestOrderReceived_method = GuiManager_type_def:get_method("isQuestOrderReceived");
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

local QuestStatus_None = getStatus_method:get_return_type():get_field("None"):get_data(nil);

local StatusType_Village = sdk_find_type_definition("snow.SnowGameManager.StatusType"):get_field("Village"):get_data(nil);

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
local currentQuestMonsterType = nil;
local MonsterListCreated = false;
local creatingList = false;

local function testAttribute(attribute, value, highest)
    imgui_table_next_column();
    if string_find(highest, attribute) then
        imgui_text(value);
    else
        imgui_text_colored(value, -65536);
    end
end

sdk_hook(isQuestOrderReceived_method, function()
    MonsterListCreated = false;
    currentQuestMonsterType = {};
    creatingList = false;
    return sdk_CALL_ORIGINAL;
end, function(retval)
    if (sdk_to_int64(retval) & 1) ~= 1 then
        creatingList = false;
        return retval;
    end

    if not creatingList then
        creatingList = true;
        local QuestManager = sdk_get_managed_singleton("snow.QuestManager");
        local GuiManager = sdk_get_managed_singleton("snow.gui.GuiManager");
        if not QuestManager
        or not GuiManager
        or not isActiveQuest_method:call(QuestManager)
        or getStatus_method:call(QuestManager) ~= QuestStatus_None
        or getQuestTargetTotalBossEmNum_method:call(QuestManager) <= 0 then
            creatingList = false;
            return retval;
        end

        local MonsterList = get_refMonsterList_method:call(GuiManager);
        local monsterListParam = monsterListParam_field:get_data(GuiManager);
        if not MonsterList or not monsterListParam then
            creatingList = false;
            return retval;
        end

        local MonsterBossData = MonsterBossData_field:get_data(MonsterList);
        if not MonsterBossData then
            creatingList = false;
            return retval;
        end

        local DataList = DataList_field:get_data(MonsterBossData);
        if not DataList then
            creatingList = false;
            return retval;
        end

        local counts = DataList_get_Count_method:call(DataList);
        if counts <= 0 then
            creatingList = false;
            return retval;
        end

        for i = 0, counts - 1, 1 do
            local monster = DataList_get_Item_method:call(DataList, i);
            if not monster then
                goto continue1;
            end

            local monsterType = EmType_field:get_data(monster);
            if not monsterType or not isQuestTargetEnemy_method:call(QuestManager, monsterType, false) then
                goto continue1;
            elseif MonsterListData[monsterType] ~= nil then
                table_insert(currentQuestMonsterType, monsterType);
                goto continue1;
            end

            local meatData = getEnemyMeatData_method:call(monsterListParam, monsterType);
            local partTableData = PartTableData_field:get_data(monster);
            if not meatData or not partTableData then
                goto continue1;
            end

            local partTableData_counts = PartTableData_get_Count_method:call(partTableData);
            if partTableData_counts <= 0 then
                goto continue1;
            end

            local MonsterDataTable = {
                Name = GetMonsterName_method:call(nil, monsterType),
                PartData = {}
            };

            for i = 0, partTableData_counts - 1, 1 do
                local part = PartTableData_get_Item_method:call(partTableData, i);
                if not part then
                    goto continue2;
                end

                local partType = Part_field:get_data(part);
                local meatType = EmPart_field:get_data(part);
                if not partType or not meatType then
                    goto continue2;
                end

                local partGuid = getMonsterPartName_method:call(MonsterList, partType);
                if not partGuid then
                    goto continue2;
                end

                local PartDataTable = {
                    PartType    = partType,
                    PartName    = GetPartName_method:call(nil, partGuid, Language.Korean),
                    MeatType    = meatType,
                    Slash       = getMeatValue_method:call(meatData, meatType, 0, MeatAttr.Slash),
                    Strike      = getMeatValue_method:call(meatData, meatType, 0, MeatAttr.Strike),
                    Shell       = getMeatValue_method:call(meatData, meatType, 0, MeatAttr.Shell),
                    Fire        = getMeatValue_method:call(meatData, meatType, 0, MeatAttr.Fire),
                    Water       = getMeatValue_method:call(meatData, meatType, 0, MeatAttr.Water),
                    Ice         = getMeatValue_method:call(meatData, meatType, 0, MeatAttr.Ice),
                    Elect       = getMeatValue_method:call(meatData, meatType, 0, MeatAttr.Elect),
                    Dragon      = getMeatValue_method:call(meatData, meatType, 0, MeatAttr.Dragon),
                    highest     = ""
                };
                local highestPhys = math_max(PartDataTable.Slash, PartDataTable.Strike, PartDataTable.Shell);
                local highestElem = math_max(PartDataTable.Fire, PartDataTable.Water, PartDataTable.Elect, PartDataTable.Ice, PartDataTable.Dragon);

                if PartDataTable.Slash == highestPhys then
                    PartDataTable.highest = PartDataTable.highest .. "_Slash";
                end
                if PartDataTable.Strike == highestPhys then
                    PartDataTable.highest = PartDataTable.highest .. "_Strike";
                end
                if PartDataTable.Shell == highestPhys then
                    PartDataTable.highest = PartDataTable.highest .. "_Shell";
                end

                if PartDataTable.Fire == highestElem then
                    PartDataTable.highest = PartDataTable.highest .. "_Fire";
                end
                if PartDataTable.Water == highestElem then
                    PartDataTable.highest = PartDataTable.highest .. "_Water";
                end
                if PartDataTable.Ice == highestElem then
                    PartDataTable.highest = PartDataTable.highest .. "_Ice";
                end
                if PartDataTable.Elect == highestElem then
                    PartDataTable.highest = PartDataTable.highest .. "_Elect";
                end
                if PartDataTable.Dragon == highestElem then
                    PartDataTable.highest = PartDataTable.highest .. "_Dragon";
                end

                table_insert(MonsterDataTable.PartData, PartDataTable);
                :: continue2 ::
            end
            MonsterListData[monsterType] = MonsterDataTable;
            table_insert(currentQuestMonsterType, monsterType);
            :: continue1 ::
        end
        MonsterListCreated = true;
    end
    creatingList = false;
    return retval;
end);

sdk_hook(questCancel_method, nil, function()
    MonsterListCreated = false;
    currentQuestMonsterType = nil;
    creatingList = false;
end);

sdk_hook(onChangedGameStatus_method, function(args)
    local Status = sdk_to_int64(args[3]) & 0xFFFFFFFF;
    if Status ~= StatusType_Village then
        MonsterListCreated = false;
        currentQuestMonsterType = nil;
        creatingList = false;
    end
    return sdk_CALL_ORIGINAL;
end);


--==--==--==--==--==--


re_on_frame(function()
    if MonsterListCreated then
        local curQuestTargetMonsterNum = #currentQuestMonsterType;
        if curQuestTargetMonsterNum >= 1 then
            imgui_push_font(font);
            if imgui_begin_window("몬스터 약점", nil, 4096 + 64) then
                for i = 1, curQuestTargetMonsterNum, 1 do
                    local curMonsterData = MonsterListData[currentQuestMonsterType[i]];
                    if imgui_begin_table("부위", 10, 1 << 21, 25) then
                        imgui_table_setup_column(curMonsterData.Name, 1 << 3, 150);
                        imgui_table_setup_column("절단", 1 << 3, 25);
                        imgui_table_setup_column("타격", 1 << 3, 25);
                        imgui_table_setup_column("탄", 1 << 3, 25);
                        imgui_table_setup_column("불", 1 << 3, 25);
                        imgui_table_setup_column("물", 1 << 3, 25);
                        imgui_table_setup_column("번개", 1 << 3, 25);
                        imgui_table_setup_column("얼음", 1 << 3, 25);
                        imgui_table_setup_column("용", 1 << 3, 25);
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
end);