local require = _G.require;
local Constants = require("Constants.Constants");
local HarvestMoonTimer = require("WetU_Overlay.HarvestMoonTimer");
local OtomoSpyUnit = require("WetU_Overlay.OtomoSpyUnit");
local QuestInfo = require("WetU_Overlay.QuestInfo");
local SpiribirdsStatus = require("WetU_Overlay.SpiribirdsStatus");

local tostring = Constants.lua.tostring;

local hook = Constants.sdk.hook;

local on_frame = Constants.re.on_frame;

local Font = Constants.Font;

local push_font = Constants.imgui.push_font;
local begin_window = Constants.imgui.begin_window;
local end_window = Constants.imgui.end_window;
local begin_table = Constants.imgui.begin_table;
local table_setup_column = Constants.imgui.table_setup_column;
local table_next_column = Constants.imgui.table_next_column;
local table_headers_row = Constants.imgui.table_headers_row;
local table_next_row = Constants.imgui.table_next_row;
local end_table = Constants.imgui.end_table;
local text = Constants.imgui.text;
local text_colored = Constants.imgui.text_colored;
local spacing = Constants.imgui.spacing;

local checkGameStatus = Constants.checkGameStatus;
--
local QuestInfo_onQuestStart = QuestInfo.onQuestStart;
local SpiribirdsStatus_onQuestStart = SpiribirdsStatus.onQuestStart;
local function onQuestStart()
	QuestInfo_onQuestStart();
	SpiribirdsStatus_onQuestStart();
end
hook(Constants.type_definitions.WwiseChangeSpaceWatcher_type_def:get_method("onQuestStart"), nil, onQuestStart);
--
local WINDOW_FLAG = 4096 + 64 + 512;
local function drawHarvestMoonTimer()
	local CircleTimer = HarvestMoonTimer.CircleTimer;

	if CircleTimer ~= nil then
		if begin_window("원월", nil, WINDOW_FLAG) == true then
			text(CircleTimer);
			end_window();
		end
	end
end

local function drawOtomoSpyUnit()
	local currentStep = OtomoSpyUnit.currentStep;

	if currentStep ~= nil then
		if begin_window("동반자 활동", nil, WINDOW_FLAG) == true then
			text(currentStep);
			end_window();
		end
	end
end

local function drawQuestInfo()
	local QuestTimer = QuestInfo.QuestTimer;
	local DeathCount = QuestInfo.DeathCount;

	if QuestTimer ~= nil then
		if begin_window("퀘스트 정보", nil, WINDOW_FLAG) == true then
			text(QuestTimer);

			if DeathCount ~= nil then
				text(DeathCount);
			end

			end_window();
		end

	elseif DeathCount ~= nil then
		if begin_window("퀘스트 정보", nil, WINDOW_FLAG) == true then
			text(DeathCount);
			end_window();
		end
	end
end

local SpiriBuffs = SpiribirdsStatus.Buffs;
local LocalizedBirdTypes = SpiribirdsStatus.LocalizedBirdTypes;
local BirdTypeToColor = SpiribirdsStatus.BirdTypeToColor;

local function drawSpiribirdsStatus()
	local SpiribirdsCall_Timer = SpiribirdsStatus.SpiribirdsCall_Timer;

	if SpiribirdsStatus.SpiribirdsHudDataCreated ~= nil then
		if begin_window("인혼조", nil, WINDOW_FLAG) == true then
			if begin_table("종류", 3, 2097152) == true then
				table_setup_column("유형", 8, 25.0);
				table_setup_column("횟수", 8, 20.0);
				table_setup_column("수치", 8, 25.0);
				table_headers_row();

				local AcquiredCounts = SpiribirdsStatus.AcquiredCounts;
				local BirdsMaxCounts = SpiribirdsStatus.BirdsMaxCounts;
				local AcquiredValues = SpiribirdsStatus.AcquiredValues;
				local StatusBuffLimits = SpiribirdsStatus.StatusBuffLimits;

				for i = 1, #SpiriBuffs, 1 do
					local buffType = SpiriBuffs[i];
					table_next_row();
					table_next_column();
					text_colored(LocalizedBirdTypes[i] .. ": ", BirdTypeToColor[i]);
					table_next_column();
					text(tostring(AcquiredCounts[buffType]) .. "/" .. tostring(BirdsMaxCounts[buffType]));
					table_next_column();
					text(tostring(AcquiredValues[buffType]) .. "/" .. tostring(StatusBuffLimits[buffType]));
				end

				end_table();
			end

			if SpiribirdsCall_Timer ~= nil then
				spacing();
				text(SpiribirdsCall_Timer);
			end

			end_window();
		end

	elseif SpiribirdsCall_Timer ~= nil then
		if begin_window("인혼조", nil, WINDOW_FLAG) == true then
			text(SpiribirdsCall_Timer);
			end_window();
		end
	end
end

local function drawMain()
	push_font(Font);
	drawHarvestMoonTimer();
	drawOtomoSpyUnit();
	drawQuestInfo();
	drawSpiribirdsStatus();
end
on_frame(drawMain);
--
HarvestMoonTimer.init();
OtomoSpyUnit.init();
QuestInfo.init();
SpiribirdsStatus.init();