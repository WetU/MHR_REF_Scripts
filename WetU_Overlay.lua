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
sdk.hook(Constants.type_definitions.WwiseChangeSpaceWatcher_type_def:get_method("onQuestStart"), nil, onQuestStart);
--
local function drawHarvestMoonTimer()
    if HarvestMoonTimer.CircleTimer == nil then
        return;
    end

    imgui.push_font(Constants.Font);
    if imgui.begin_window("원월", nil, 4096 + 64 + 512) == true then
        imgui.text(HarvestMoonTimer.CircleTimer);
        imgui.end_window();
    end

    imgui.pop_font();
end

local function drawOtomoSpyUnit()
    if OtomoSpyUnit.currentStep == nil then
        return;
    end

    imgui.push_font(Constants.Font);
    if imgui.begin_window("동반자 활동", nil, 4096 + 64 + 512) == true then
        imgui.text(OtomoSpyUnit.currentStep);
        imgui.end_window();
    end

    imgui.pop_font();
end

local function drawQuestInfo()
    if QuestInfo.QuestTimer == nil and QuestInfo.DeathCount == nil then
        return;
    end

    imgui.push_font(Constants.Font);
    if imgui.begin_window("퀘스트 정보", nil, 4096 + 64 + 512) == true then
        if QuestInfo.QuestTimer ~= nil then
            imgui.text(QuestInfo.QuestTimer);
        end

        if QuestInfo.DeathCount ~= nil then
            imgui.text(QuestInfo.DeathCount);
        end

        imgui.end_window();
    end

    imgui.pop_font();
end

local function drawSpiribirdsStatus()
    if SpiribirdsStatus.SpiribirdsHudDataCreated == nil and SpiribirdsStatus.SpiribirdsCall_Timer == nil then
        return;
    end

    imgui.push_font(Constants.Font);
    if imgui.begin_window("인혼조", nil, 4096 + 64 + 512) == true then
        if SpiribirdsStatus.SpiribirdsHudDataCreated ~= nil then
            if imgui.begin_table("종류", 3, 2097152) == true then
                imgui.table_setup_column("유형", 8, 25.0);
                imgui.table_setup_column("횟수", 8, 20.0);
                imgui.table_setup_column("수치", 8, 25.0);
                imgui.table_headers_row();
                for i = 1, #SpiribirdsStatus.Buffs, 1 do
                    local buffType = SpiribirdsStatus.Buffs[i];
                    imgui.table_next_row();
                    imgui.table_next_column();
                    imgui.text_colored(SpiribirdsStatus.LocalizedBirdTypes[i] .. ": ", SpiribirdsStatus.BirdTypeToColor[i]);
                    imgui.table_next_column();
                    imgui.text(tostring(SpiribirdsStatus.AcquiredCounts[buffType]) .. "/" .. tostring(SpiribirdsStatus.BirdsMaxCounts[buffType]));
                    imgui.table_next_column();
                    imgui.text(tostring(SpiribirdsStatus.AcquiredValues[buffType]) .. "/" .. tostring(SpiribirdsStatus.StatusBuffLimits[buffType]));
                end
                imgui.end_table();
            end

            if SpiribirdsStatus.SpiribirdsCall_Timer ~= nil then
                imgui.spacing();
                imgui.text(SpiribirdsStatus.SpiribirdsCall_Timer);
            end
        else
            imgui.text(SpiribirdsStatus.SpiribirdsCall_Timer);
        end

        imgui.end_window();
    end

    imgui.pop_font();
end

local function drawMain()
    drawHarvestMoonTimer();
    drawOtomoSpyUnit();
    drawQuestInfo();
    drawSpiribirdsStatus();
end
re.on_frame(drawMain);
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