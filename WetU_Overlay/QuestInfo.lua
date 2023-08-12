local Constants = _G.require("Constants.Constants");

local tostring = Constants.lua.tostring;
local string_format = Constants.lua.string_format;

local find_type_definition = Constants.sdk.find_type_definition;
local get_managed_singleton = Constants.sdk.get_managed_singleton;
local hook = Constants.sdk.hook;

local checkGameStatus = Constants.checkGameStatus;
local getQuestLife = Constants.getQuestLife;
local getDeathNum = Constants.getDeathNum;
--
local this = {
	QuestManager = nil,
	init = true,
	onQuestStart = true,
	QuestTimer = nil,
	DeathCount = nil
};
--
local getClearTimeFormatText_method = find_type_definition("snow.gui.SnowGuiCommonUtility"):get_method("getClearTimeFormatText(System.Single)"); -- static
--
local QuestManager_type_def = Constants.type_definitions.QuestManager_type_def;
local getQuestMaxTimeMin_method = QuestManager_type_def:get_method("getQuestMaxTimeMin");
local isQuestMaxTimeUnlimited_method = QuestManager_type_def:get_method("isQuestMaxTimeUnlimited");
local getQuestElapsedTimeSec_method = QuestManager_type_def:get_method("getQuestElapsedTimeSec");
local isTourQuest_method = QuestManager_type_def:get_method("isTourQuest");
--
local isTourQuest = false;
local curQuestLife = nil;
local curQuestMaxTimeMin = nil;

function this:getQuestManager()
	if self.QuestManager == nil then
		self.QuestManager = get_managed_singleton("snow.QuestManager");
	end

	return self.QuestManager;
end

local function onQuestStart()
	local QuestManager = this:getQuestManager();
	isTourQuest = isTourQuest_method:call(QuestManager);

	if curQuestLife == nil then
		curQuestLife = isTourQuest == true and "제한 없음" or getQuestLife(QuestManager);
	end

	this.DeathCount = string_format("다운 횟수: %d / %s", getDeathNum(QuestManager), curQuestLife);

	curQuestMaxTimeMin = (isTourQuest == true or isQuestMaxTimeUnlimited_method:call(QuestManager) == true) and "제한 없음" or tostring(getQuestMaxTimeMin_method:call(QuestManager)) .. "분";
	this.QuestTimer = string_format("%s / %s", getClearTimeFormatText_method:call(nil, getQuestElapsedTimeSec_method:call(QuestManager)), curQuestMaxTimeMin);
end

local function updateDeathCount()
	local QuestManager = this:getQuestManager();

	if curQuestLife == nil then
		curQuestLife = isTourQuest == true and "제한 없음" or getQuestLife(QuestManager);
	end

	this.DeathCount = string_format("다운 횟수: %d / %s", getDeathNum(QuestManager), curQuestLife);
end

local function updateQuestTimer()
	this.QuestTimer = string_format("%s / %s", getClearTimeFormatText_method:call(nil, getQuestElapsedTimeSec_method:call(this:getQuestManager())), curQuestMaxTimeMin);
end

local function Terminate()
	this.QuestTimer = nil;
	this.DeathCount = nil;
	isTourQuest = false;
	curQuestLife = nil;
	curQuestMaxTimeMin = nil;
end

local function init()
	if checkGameStatus(2) == true then
		onQuestStart();
	end

	hook(QuestManager_type_def:get_method("questForfeit(System.Int32, System.UInt32)"), nil, updateDeathCount);
	hook(QuestManager_type_def:get_method("updateQuestTime"), nil, updateQuestTimer);
	hook(QuestManager_type_def:get_method("onQuestEnd"), nil, Terminate);
end

this.init = init;
this.onQuestStart = onQuestStart;
--
return this;