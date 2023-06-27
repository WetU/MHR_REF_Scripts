local require = require;
local Constants = require("Constants.Constants");
local EmWeakness = require("WetU_Overlay.EmWeakness");
local SpiribirdsStatus = require("WetU_Overlay.SpiribirdsStatus");
local HarvestMoonTimer = require("WetU_Overlay.HarvestMoonTimer");
if not Constants
or not EmWeakness
or not SpiribirdsStatus
or not HarvestMoonTimer then
	return;
end
--
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
--
local function buildBirdTypeToTable(buffType)
    Constants.IMGUI.table_next_row();
    Constants.IMGUI.table_next_column();
    Constants.IMGUI.text_colored(LocalizedBirdTypes[buffType] .. ": ", BirdTypeToColor[buffType]);
    Constants.IMGUI.table_next_column();
    Constants.IMGUI.text(Constants.LUA.tostring(SpiribirdsStatus.AcquiredCounts[buffType]) .. "/" .. Constants.LUA.tostring(SpiribirdsStatus.BirdsMaxCounts[buffType]));
    Constants.IMGUI.table_next_column();
    Constants.IMGUI.text(Constants.LUA.tostring(SpiribirdsStatus.AcquiredValues[buffType]) .. "/" .. Constants.LUA.tostring(SpiribirdsStatus.StatusBuffLimits[buffType]));
end

Constants.RE.on_frame(function()
    if EmWeakness.EmAilmentData ~= nil then
        Constants.IMGUI.push_font(Constants.Font);
        if Constants.IMGUI.begin_window("몬스터 약점", nil, 4096 + 64 + 512) then
            local curEmNum = #EmWeakness.EmAilmentData;
            for i = 1, curEmNum, 1 do
                local curEmData = EmWeakness.EmAilmentData[i];
                Constants.IMGUI.text(curEmData.Name);
                if Constants.IMGUI.begin_table("상태 이상", 10, 2097152) then
                    for j = 1, #LocalizedConditionType, 1 do
                        if j == 6 then
                            Constants.IMGUI.table_setup_column(LocalizedConditionType[j], 8, 5.0);
                        elseif j == 1 or j == 7 or j == 8 then
                            Constants.IMGUI.table_setup_column("   " .. LocalizedConditionType[j], 8, 3.0);
                        else
                            Constants.IMGUI.table_setup_column(" " .. LocalizedConditionType[j], 8, 3.0);
                        end
                    end

                    Constants.IMGUI.table_headers_row();
                    Constants.IMGUI.table_next_row();

                    for k = 1, #curEmData.ConditionData, 1 do
                        local value = curEmData.ConditionData[k];
                        Constants.IMGUI.table_next_column();
                        if k == 6 then
                            Constants.IMGUI.text_colored("       " .. Constants.LUA.tostring(value), value == curEmData.ConditionData.HighestCondition and 4278190335 or 4294901760);
                        else
                            Constants.IMGUI.text_colored("    " .. Constants.LUA.tostring(value), value == curEmData.ConditionData.HighestCondition and 4278190335 or 4294901760);
                        end
                    end
                    Constants.IMGUI.end_table();
                end
                if i < curEmNum then
                    Constants.IMGUI.spacing();
                end
            end
            Constants.IMGUI.end_window();
        end
        Constants.IMGUI.pop_font();
    end

    if SpiribirdsStatus.SpiribirdsHudDataCreated ~= nil then
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
            if SpiribirdsStatus.SpiribirdsCall_Timer ~= nil then
                Constants.IMGUI.spacing();
                Constants.IMGUI.text(SpiribirdsStatus.SpiribirdsCall_Timer);
            end
            Constants.IMGUI.end_window();
        end
        Constants.IMGUI.pop_font();
    elseif SpiribirdsStatus.SpiribirdsCall_Timer ~= nil then
        Constants.IMGUI.push_font(Constants.Font);
        if Constants.IMGUI.begin_window("인혼조", nil, 4096 + 64 + 512) then
            Constants.IMGUI.text(SpiribirdsStatus.SpiribirdsCall_Timer);
            Constants.IMGUI.end_window();
        end
        Constants.IMGUI.pop_font();
    end

    if HarvestMoonTimer.CircleTimer ~= nil then
        Constants.IMGUI.push_font(Constants.Font);
        if Constants.IMGUI.begin_window("원월", nil, 4096 + 64 + 512) then
            Constants.IMGUI.text(HarvestMoonTimer.CircleTimer);
            Constants.IMGUI.end_window();
        end
        Constants.IMGUI.pop_font();
    end
end);
--
EmWeakness.init();
SpiribirdsStatus.init();
HarvestMoonTimer.init();