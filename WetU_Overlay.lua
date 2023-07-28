local require = require;
local Constants = require("Constants.Constants");
local HarvestMoonTimer = require("WetU_Overlay.HarvestMoonTimer");
local OtomoSpyUnit = require("WetU_Overlay.OtomoSpyUnit");
local QuestInfo = require("WetU_Overlay.QuestInfo");
local SpiribirdsStatus = require("WetU_Overlay.SpiribirdsStatus");
--
local function onQuestStart()
    QuestInfo.onQuestStart();
    SpiribirdsStatus.onQuestStart();
end
Constants.SDK.hook(Constants.type_definitions.WwiseChangeSpaceWatcher_type_def:get_method("onQuestStart"), nil, onQuestStart);
--
local function drawHarvestMoonTimer()
    if HarvestMoonTimer.CircleTimer == nil then
        return;
    end

    Constants.IMGUI.push_font(Constants.Font);
    if Constants.IMGUI.begin_window("원월", nil, 4096 + 64 + 512) == true then
        Constants.IMGUI.text(HarvestMoonTimer.CircleTimer);
        Constants.IMGUI.end_window();
    end

    Constants.IMGUI.pop_font();
end

local function drawOtomoSpyUnit()
    if OtomoSpyUnit.currentStep == nil then
        return;
    end

    Constants.IMGUI.push_font(Constants.Font);
    if Constants.IMGUI.begin_window("동반자 활동", nil, 4096 + 64 + 512) == true then
        Constants.IMGUI.text(OtomoSpyUnit.currentStep);
        Constants.IMGUI.end_window();
    end

    Constants.IMGUI.pop_font();
end

local function drawQuestInfo()
    if QuestInfo.QuestTimer == nil and QuestInfo.DeathCount == nil then
        return;
    end

    Constants.IMGUI.push_font(Constants.Font);
    if Constants.IMGUI.begin_window("퀘스트 정보", nil, 4096 + 64 + 512) == true then
        if QuestInfo.QuestTimer ~= nil then
            Constants.IMGUI.text(QuestInfo.QuestTimer);
        end

        if QuestInfo.DeathCount ~= nil then
            Constants.IMGUI.text(QuestInfo.DeathCount);
        end

        Constants.IMGUI.end_window();
    end

    Constants.IMGUI.pop_font();
end

local function drawSpiribirdsStatus()
    if SpiribirdsStatus.SpiribirdsHudDataCreated == nil and SpiribirdsStatus.SpiribirdsCall_Timer == nil then
        return;
    end

    Constants.IMGUI.push_font(Constants.Font);
    if Constants.IMGUI.begin_window("인혼조", nil, 4096 + 64 + 512) == true then
        if SpiribirdsStatus.SpiribirdsHudDataCreated ~= nil then
            if Constants.IMGUI.begin_table("종류", 3, 2097152) == true then
                Constants.IMGUI.table_setup_column("유형", 8, 25.0);
                Constants.IMGUI.table_setup_column("횟수", 8, 20.0);
                Constants.IMGUI.table_setup_column("수치", 8, 25.0);
                Constants.IMGUI.table_headers_row();
                for i = 1, #SpiribirdsStatus.Buffs, 1 do
                    local buffType = SpiribirdsStatus.Buffs[i];
                    Constants.IMGUI.table_next_row();
                    Constants.IMGUI.table_next_column();
                    Constants.IMGUI.text_colored(SpiribirdsStatus.LocalizedBirdTypes[i] .. ": ", SpiribirdsStatus.BirdTypeToColor[i]);
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
        else
            Constants.IMGUI.text(SpiribirdsStatus.SpiribirdsCall_Timer);
        end

        Constants.IMGUI.end_window();
    end

    Constants.IMGUI.pop_font();
end

local function drawMain()
    drawHarvestMoonTimer();
    drawOtomoSpyUnit();
    drawQuestInfo();
    drawSpiribirdsStatus();
end
Constants.RE.on_frame(drawMain);
--
HarvestMoonTimer.init();
OtomoSpyUnit.init();
QuestInfo.init();
SpiribirdsStatus.init();

if Constants.checkGameStatus(Constants.GameStatusType.Village) == true then
    OtomoSpyUnit.get_currentStepCount();
elseif Constants.checkGameStatus(Constants.GameStatusType.Quest) == true then
    QuestInfo.onQuestStart();
    SpiribirdsStatus.CreateData();
end