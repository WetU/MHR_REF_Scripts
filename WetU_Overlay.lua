local require = _G.require;
local Constants = require("Constants.Constants");
local HarvestMoonTimer = require("WetU_Overlay.HarvestMoonTimer");
local OtomoSpyUnit = require("WetU_Overlay.OtomoSpyUnit");
local QuestInfo = require("WetU_Overlay.QuestInfo");
local SpiribirdsStatus = require("WetU_Overlay.SpiribirdsStatus");

local lua = Constants.lua;
local on_frame = Constants.on_frame;
local Font = Constants.Font;
local imgui = Constants.imgui;

local pairs = lua.pairs;
local tostring = lua.tostring;

local to_managed_object = Constants.sdk.to_managed_object;

local push_font = imgui.push_font;
local begin_window = imgui.begin_window;
local end_window = imgui.end_window;
local begin_table = imgui.begin_table;
local table_setup_column = imgui.table_setup_column;
local table_next_column = imgui.table_next_column;
local table_headers_row = imgui.table_headers_row;
local table_next_row = imgui.table_next_row;
local end_table = imgui.end_table;
local text = imgui.text;
local text_colored = imgui.text_colored;
local spacing = imgui.spacing;
--
local addItemToPouch_method = Constants.type_definitions.DataShortcut_type_def:get_method("addItemToPouch(snow.data.ContentsIdSystem.ItemId, System.UInt32)"); -- static
--
local QuestInfo_onQuestStart = QuestInfo.onQuestStart;
local SpiribirdsStatus_onQuestStart = SpiribirdsStatus.onQuestStart;
--
local GuiQuestStart_type_def = Constants.sdk.find_type_definition("snow.gui.GuiQuestStart");
local NowState_field = GuiQuestStart_type_def:get_field("_NowState");
--
local AutoAddItemIds = {
	[68157940] = 10, -- 지급전용 휴대 식량
	[68157942] = 10, -- 그레이트 응급약
	[68157954] = 1  -- 지급전용 귀환옥
};

local GuiQuestStart = nil;
local function Prehook_QuestStart(args)
	GuiQuestStart = to_managed_object(args[2]);
end
local function PostHook_QuestStart()
	if NowState_field:get_data(GuiQuestStart) == 3 then
		QuestInfo_onQuestStart();
		SpiribirdsStatus_onQuestStart();
		for k, v in pairs(AutoAddItemIds) do
			addItemToPouch_method:call(nil, k, v);
		end
	end

	GuiQuestStart = nil;
end
Constants.sdk.hook(GuiQuestStart_type_def:get_method("lateUpdate"), Prehook_QuestStart, PostHook_QuestStart);
--
local WINDOW_FLAG = 4096 + 64 + 512;

local function drawHarvestMoonTimer()
	local CircleTimer = HarvestMoonTimer.CircleTimer;

	if CircleTimer ~= nil then
		if begin_window("원월", nil, WINDOW_FLAG) == true then
			if HarvestMoonTimer.IsWarning == true then
				text_colored(CircleTimer, 4278190335);
			else
				text(CircleTimer);
			end
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
	if QuestInfo.QuestInfoDataCreated == true then
		if begin_window("퀘스트 정보", nil, WINDOW_FLAG) == true then
			text(QuestInfo.QuestTimer);
			text(QuestInfo.DeathCount);
			end_window();
		end
	end
end

local StaticBuffData = {
	LocalizedNames = {
		"공격력",
		"방어력",
		"체력",
		"스태미나"
	},
	Colors = {
		4278190335,
		4278222847,
		4278222848,
		4278255615
	}
};

local function drawSpiribirdsStatus()
	if SpiribirdsStatus.SpiribirdsHudDataCreated == true then
		if begin_window("인혼조", nil, WINDOW_FLAG) == true then
			if begin_table("종류", 3, 2097152) == true then
				local AcquiredCounts = SpiribirdsStatus.AcquiredCounts;
				local BirdsMaxCounts = SpiribirdsStatus.BirdsMaxCounts;
				local AcquiredValues = SpiribirdsStatus.AcquiredValues;
				local StatusBuffLimits = SpiribirdsStatus.StatusBuffLimits;

				table_setup_column("유형", 8, 25.0);
				table_setup_column("횟수", 8, 20.0);
				table_setup_column("수치", 8, 25.0);
				table_headers_row();

				for i = 1, 4, 1 do
					table_next_row();
					table_next_column();
					text_colored(StaticBuffData.LocalizedNames[i] .. ": ", StaticBuffData.Colors[i]);
					table_next_column();
					text(tostring(AcquiredCounts[i]) .. "/" .. tostring(BirdsMaxCounts[i]));
					table_next_column();
					text(tostring(AcquiredValues[i]) .. "/" .. tostring(StatusBuffLimits[i]));
				end

				end_table();
			end

			if SpiribirdsStatus.SpiribirdsCall_Timer ~= nil then
				spacing();
				text(SpiribirdsCall_Timer);
			end

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