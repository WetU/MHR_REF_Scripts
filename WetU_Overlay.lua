local require = require;
local Constants = require("Constants.Constants");
local SpiribirdsStatus = require("WetU_Overlay.SpiribirdsStatus");
local HarvestMoonTimer = require("WetU_Overlay.HarvestMoonTimer");
local OtomoSpyUnit = require("WetU_Overlay.OtomoSpyUnit");

if not Constants
or not SpiribirdsStatus
or not HarvestMoonTimer
or not OtomoSpyUnit then
	return;
end
--
local BuffTypes = {
    "Atk",
    "Def",
    "Vital",
    "Stamina"
};

local LocalizedBirdTypes = {
    "공격력",
    "방어력",
    "체력",
    "스태미나"
};

local BirdTypeToColor = {
    4278190335,
    4278222847,
    4278222848,
    4278255615
};
--
Constants.RE.on_frame(function()
    if SpiribirdsStatus.SpiribirdsHudDataCreated ~= nil then
        Constants.IMGUI.push_font(Constants.Font);
        if Constants.IMGUI.begin_window("인혼조", nil, 4096 + 64 + 512) == true then
            if Constants.IMGUI.begin_table("종류", 3, 2097152) == true then
                Constants.IMGUI.table_setup_column("유형", 8, 25.0);
                Constants.IMGUI.table_setup_column("횟수", 8, 20.0);
                Constants.IMGUI.table_setup_column("수치", 8, 25.0);
                Constants.IMGUI.table_headers_row();
                for i = 1, #BuffTypes, 1 do
                    Constants.IMGUI.table_next_row();
                    Constants.IMGUI.table_next_column();
                    Constants.IMGUI.text_colored(LocalizedBirdTypes[i] .. ": ", BirdTypeToColor[i]);
                    Constants.IMGUI.table_next_column();
                    Constants.IMGUI.text(Constants.LUA.tostring(SpiribirdsStatus.AcquiredCounts[BuffTypes[i]]) .. "/" .. Constants.LUA.tostring(SpiribirdsStatus.BirdsMaxCounts[BuffTypes[i]]));
                    Constants.IMGUI.table_next_column();
                    Constants.IMGUI.text(Constants.LUA.tostring(SpiribirdsStatus.AcquiredValues[BuffTypes[i]]) .. "/" .. Constants.LUA.tostring(SpiribirdsStatus.StatusBuffLimits[BuffTypes[i]]));
                end
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
        if Constants.IMGUI.begin_window("인혼조", nil, 4096 + 64 + 512) == true then
            Constants.IMGUI.text(SpiribirdsStatus.SpiribirdsCall_Timer);
            Constants.IMGUI.end_window();
        end
        Constants.IMGUI.pop_font();
    end

    if HarvestMoonTimer.CircleTimer ~= nil then
        Constants.IMGUI.push_font(Constants.Font);
        if Constants.IMGUI.begin_window("원월", nil, 4096 + 64 + 512) == true then
            Constants.IMGUI.text(HarvestMoonTimer.CircleTimer);
            Constants.IMGUI.end_window();
        end
        Constants.IMGUI.pop_font();
    end

    if OtomoSpyUnit.currentStep ~= nil then
        Constants.IMGUI.push_font(Constants.Font);
        if Constants.IMGUI.begin_window("동반자 활동", nil, 4096 + 64 + 512) == true then
            Constants.IMGUI.text(OtomoSpyUnit.currentStep);
            Constants.IMGUI.end_window();
        end
        Constants.IMGUI.pop_font();
    end
end);
--
SpiribirdsStatus.init();
HarvestMoonTimer.init();
OtomoSpyUnit.init();