local require = require;
local Constants = require("Constants.Constants");
local HarvestMoonTimer = require("WetU_Overlay.HarvestMoonTimer");
local OtomoSpyUnit = require("WetU_Overlay.OtomoSpyUnit");
local QuestInfo = require("WetU_Overlay.QuestInfo");
local SpiribirdsStatus = require("WetU_Overlay.SpiribirdsStatus");

if Constants == nil
or HarvestMoonTimer == nil
or OtomoSpyUnit == nil
or QuestInfo == nil
or SpiribirdsStatus == nil then
	return;
end
--
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
local function onchangeMasterPlayerID(args)
    Constants.GetMasterPlayerId(Constants.SDK.to_int64(args[3]));
end
Constants.SDK.hook(Constants.type_definitions.PlayerManager_type_def:get_method("changeMasterPlayerID(snow.player.PlayerIndex)"), onchangeMasterPlayerID);
--
local function draw()
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

    if QuestInfo.QuestTimer ~= nil then
        Constants.IMGUI.push_font(Constants.Font);
        if Constants.IMGUI.begin_window("퀘스트 정보", nil, 4096 + 64 + 512) == true then
            Constants.IMGUI.text(QuestInfo.QuestTimer);
            if QuestInfo.DeathCount ~= nil then
                Constants.IMGUI.text(QuestInfo.DeathCount);
            end
            Constants.IMGUI.end_window();
        end
        Constants.IMGUI.pop_font();
    elseif QuestInfo.DeathCount ~= nil then
        Constants.IMGUI.push_font(Constants.Font);
        if Constants.IMGUI.begin_window("퀘스트 정보", nil, 4096 + 64 + 512) == true then
            Constants.IMGUI.text(QuestInfo.DeathCount);
            Constants.IMGUI.end_window();
        end
        Constants.IMGUI.pop_font();
    end

    if SpiribirdsStatus.SpiribirdsHudDataCreated ~= nil then
        Constants.IMGUI.push_font(Constants.Font);
        if Constants.IMGUI.begin_window("인혼조", nil, 4096 + 64 + 512) == true then
            if Constants.IMGUI.begin_table("종류", 3, 2097152) == true then
                Constants.IMGUI.table_setup_column("유형", 8, 25.0);
                Constants.IMGUI.table_setup_column("횟수", 8, 20.0);
                Constants.IMGUI.table_setup_column("수치", 8, 25.0);
                Constants.IMGUI.table_headers_row();
                for i = 1, #SpiribirdsStatus.Buffs, 1 do
                    local buffType = SpiribirdsStatus.Buffs[i];
                    Constants.IMGUI.table_next_row();
                    Constants.IMGUI.table_next_column();
                    Constants.IMGUI.text_colored(LocalizedBirdTypes[i] .. ": ", BirdTypeToColor[i]);
                    Constants.IMGUI.table_next_column();
                    Constants.IMGUI.text(Constants.LUA.tostring(SpiribirdsStatus.AcquiredCounts[buffType]) .. "/" .. Constants.LUA.tostring(SpiribirdsStatus.BirdsMaxCounts[buffType]));
                    Constants.IMGUI.table_next_column();
                    Constants.IMGUI.text(Constants.LUA.tostring(SpiribirdsStatus.AcquiredValues[buffType]) .. "/" .. Constants.LUA.tostring(SpiribirdsStatus.StatusBuffLimits[buffType]));
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
end
Constants.RE.on_frame(draw);
--
HarvestMoonTimer.init();
OtomoSpyUnit.init();
QuestInfo.init();
SpiribirdsStatus.init();