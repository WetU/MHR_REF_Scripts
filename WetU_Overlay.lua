local require = require;
local Constants = require("Constants.Constants");
if not Constants then
	return;
end

local EmWeakness = require("WetU_Overlay.EmWeakness");
local SpiribirdsStatus = require("WetU_Overlay.SpiribirdsStatus");
local HarvestMoonTimer = require("WetU_Overlay.HarvestMoonTimer");


--==--==--==--==--==--


Constants.SDK.hook(SpiribirdsStatus.PlayerQuestBase_type_def:get_method("onDestroy"), nil, function()
    SpiribirdsStatus.TerminateSpiribirdsHud();
    Constants.MasterPlayerIndex = nil;
    HarvestMoonTimer.CircleTimer = nil;
end);

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
    Constants.IMGUI.table_next_column();
    Constants.IMGUI.text_colored(" " .. Constants.LUA.tostring(value), Constants.LUA.string_find(highest, attribute) and 4278190335 or 4294901760);
end

local function buildBirdTypeToTable(type)
    Constants.IMGUI.table_next_row();
    Constants.IMGUI.table_next_column();
    Constants.IMGUI.text_colored(LocalizedBirdTypes[type] .. ": ", BirdTypeToColor[type]);
    Constants.IMGUI.table_next_column();
    Constants.IMGUI.text(Constants.LUA.tostring(SpiribirdsStatus.AcquiredCounts[type]) .. "/" .. Constants.LUA.tostring(SpiribirdsStatus.BirdsMaxCounts[type]));
    Constants.IMGUI.table_next_column();
    Constants.IMGUI.text(Constants.LUA.tostring(SpiribirdsStatus.AcquiredValues[type]) .. "/" .. Constants.LUA.tostring(SpiribirdsStatus.StatusBuffLimits[type]));
end

Constants.RE.on_frame(function()
    if EmWeakness.currentQuestMonsterTypes then
        Constants.IMGUI.push_font(Constants.Font);
        if Constants.IMGUI.begin_window("몬스터 약점", nil, 4096 + 64 + 512) then
            local curQuestTargetMonsterNum = #EmWeakness.currentQuestMonsterTypes;
            for i = 1, curQuestTargetMonsterNum, 1 do
                local curMonsterData = EmWeakness.MonsterListData[EmWeakness.currentQuestMonsterTypes[i]];
                if Constants.IMGUI.begin_table("속성", 9, 2097152) then
                    Constants.IMGUI.table_setup_column(curMonsterData.Name, 8, 20.0);

                    for j = 1, #LocalizedMeatAttr, 1 do
                        if (j >= 3 and j <= 5) or j == 8 then
                            Constants.IMGUI.table_setup_column(" " .. LocalizedMeatAttr[j], 8, 3.0);
                        else
                            Constants.IMGUI.table_setup_column(LocalizedMeatAttr[j], 8, 3.0);
                        end
                    end
                    
                    Constants.IMGUI.table_headers_row();

                    for _, part in Constants.LUA.pairs(curMonsterData.PartData) do
                        Constants.IMGUI.table_next_row();
                        Constants.IMGUI.table_next_column();
                        Constants.IMGUI.text(part.PartName);

                        testAttribute("Slash", part.MeatValues.Slash, part.HighestMeat);
                        testAttribute("Strike", part.MeatValues.Strike, part.HighestMeat);
                        testAttribute("Shell", part.MeatValues.Shell, part.HighestMeat);
                        testAttribute("Fire", part.MeatValues.Fire, part.HighestMeat);
                        testAttribute("Water", part.MeatValues.Water, part.HighestMeat);
                        testAttribute("Ice", part.MeatValues.Ice, part.HighestMeat);
                        testAttribute("Elect", part.MeatValues.Elect, part.HighestMeat);
                        testAttribute("Dragon", part.MeatValues.Dragon, part.HighestMeat);
                    end
                    Constants.IMGUI.end_table();
                end
                if Constants.IMGUI.begin_table("상태 이상", 10, 2097152) then
                    for k = 1, 10, 1 do
                        if k == 6 then
                            Constants.IMGUI.table_setup_column(LocalizedConditionType[k], 8, 5.0);
                        elseif k == 1 or k == 7 or k == 8 then
                            Constants.IMGUI.table_setup_column("   " .. LocalizedConditionType[k], 8, 3.0);
                        else
                            Constants.IMGUI.table_setup_column(" " .. LocalizedConditionType[k], 8, 3.0);
                        end
                    end

                    Constants.IMGUI.table_headers_row();
                    Constants.IMGUI.table_next_row();

                    for m = 1, 10, 1 do
                        local value = curMonsterData.ConditionData[m];
                        Constants.IMGUI.table_next_column();
                        if m == 6 then
                            Constants.IMGUI.text_colored("       " .. Constants.LUA.tostring(value), value == curMonsterData.ConditionData.HighestCondition and 4278190335 or 4294901760);
                        else
                            Constants.IMGUI.text_colored("    " .. Constants.LUA.tostring(value), value == curMonsterData.ConditionData.HighestCondition and 4278190335 or 4294901760);
                        end
                    end
                    Constants.IMGUI.end_table();
                end
                if i < curQuestTargetMonsterNum then
                    Constants.IMGUI.spacing();
                end
            end
            Constants.IMGUI.end_window();
        end
        Constants.IMGUI.pop_font();
    end

    if SpiribirdsStatus.SpiribirdsHudDataCreated then
        Constants.IMGUI.push_font(Constants.Font);
        if Constants.IMGUI.begin_window("인혼조", nil, 4096 + 64 + 512) then
            if Constants.IMGUI.begin_table("종류", 3, 2097152) then
                Constants.IMGUI.table_setup_column("유형", 8, 25.0);
                Constants.IMGUI.table_setup_column("횟수", 8, 20.0);
                Constants.IMGUI.table_setup_column("수치", 8, 25.0);
                Constants.IMGUI.table_headers_row();
                buildBirdTypeToTable("Atk");
                buildBirdTypeToTable("Def");
                buildBirdTypeToTable("Vital");
                buildBirdTypeToTable("Stamina");
                Constants.IMGUI.end_table();
            end
            if SpiribirdsStatus.SpiribirdsCall_Timer then
                Constants.IMGUI.spacing();
                Constants.IMGUI.text(SpiribirdsStatus.SpiribirdsCall_Timer);
            end
            Constants.IMGUI.end_window();
        end
        Constants.IMGUI.pop_font();
    elseif SpiribirdsStatus.SpiribirdsCall_Timer then
        Constants.IMGUI.push_font(Constants.Font);
        if Constants.IMGUI.begin_window("인혼조", nil, 4096 + 64 + 512) then
            Constants.IMGUI.text(SpiribirdsStatus.SpiribirdsCall_Timer);
            Constants.IMGUI.end_window();
        end
        Constants.IMGUI.pop_font();
    end

    if HarvestMoonTimer.CircleTimer then
        Constants.IMGUI.push_font(Constants.Font);
        if Constants.IMGUI.begin_window("원월", nil, 4096 + 64 + 512) then
            Constants.IMGUI.text(HarvestMoonTimer.CircleTimer);
            Constants.IMGUI.end_window();
        end
        Constants.IMGUI.pop_font();
    end
end);