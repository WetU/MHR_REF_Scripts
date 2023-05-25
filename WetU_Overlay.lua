local require = require;

local pairs = pairs;
local tostring = tostring;

local string = string;
local string_find = string.find;

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
--
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
--
local EmWeakness = require("WetU_Overlay.EmWeakness");
local SpiribirdsStatus = require("WetU_Overlay.SpiribirdsStatus");
local HarvestMoonTimer = require("WetU_Overlay.HarvestMoonTimer");


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
    ["Def"] = 4286513407,
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
    imgui_text(tostring(SpiribirdsStatus.AcquiredCounts[type]) .. "/" .. tostring(SpiribirdsStatus.BirdsMaxCounts[type]));
    imgui_table_next_column();
    imgui_text(tostring(SpiribirdsStatus.AcquiredValues[type]) .. "/" .. tostring(SpiribirdsStatus.StatusBuffLimits[type]));
end

re.on_frame(function()
    if EmWeakness.currentQuestMonsterTypes then
        imgui_push_font(font);
        if imgui_begin_window("몬스터 약점", nil, 4096 + 64 + 512) then
            local curQuestTargetMonsterNum = #EmWeakness.currentQuestMonsterTypes;
            for i = 1, curQuestTargetMonsterNum, 1 do
                local curMonsterData = EmWeakness.MonsterListData[EmWeakness.currentQuestMonsterTypes[i]];
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

    if SpiribirdsStatus.SpiribirdsHudDataCreated or SpiribirdsStatus.SpiribirdsCall_Timer then
        imgui_push_font(font);
        if imgui_begin_window("인혼조", nil, 4096 + 64 + 512) then
            if SpiribirdsStatus.SpiribirdsHudDataCreated then
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
                if SpiribirdsStatus.SpiribirdsCall_Timer then
                    imgui_spacing();
                    imgui_text(SpiribirdsStatus.SpiribirdsCall_Timer);
                end
            else
                imgui_text(SpiribirdsStatus.SpiribirdsCall_Timer);
            end
            imgui_end_window();
        end
        imgui_pop_font();
    end

    if HarvestMoonTimer.HarvestMoonTimer_Inside or HarvestMoonTimer.HarvestMoonTimer_Outside then
        imgui_push_font(font);
        if imgui_begin_window("원월", nil, 4096 + 64 + 512) then
            if HarvestMoonTimer.HarvestMoonTimer_Inside then
                imgui_text(HarvestMoonTimer.HarvestMoonTimer_Inside);
            end
            if HarvestMoonTimer.HarvestMoonTimer_Outside then
                imgui_text(HarvestMoonTimer.HarvestMoonTimer_Outside);
            end
            imgui_end_window();
        end
        imgui_pop_font();
    end
end);