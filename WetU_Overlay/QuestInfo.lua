local Constants = _G.require("Constants.Constants");

local lua = Constants.lua;
local sdk = Constants.sdk;

local tostring = lua.tostring;
local string_format = lua.string_format;

local hook = sdk.hook;
--
local this = {
	["init"] = true,
	["onQuestStart"] = true,
	["QuestInfoDataCreated"] = false,
	["QuestTimer"] = nil,
	["DeathCount"] = nil
};
--
local getClearTimeFormatText_method = sdk.find_type_definition("snow.gui.SnowGuiCommonUtility"):get_method("getClearTimeFormatText(System.Single)"); -- static
--
local QuestManager_type_def = Constants.type_definitions.QuestManager_type_def;
local getQuestMaxTimeMin_method = QuestManager_type_def:get_method("getQuestMaxTimeMin");
local isQuestMaxTimeUnlimited_method = QuestManager_type_def:get_method("isQuestMaxTimeUnlimited");
local getQuestElapsedTimeSec_method = QuestManager_type_def:get_method("getQuestElapsedTimeSec");
local isTourQuest_method = QuestManager_type_def:get_method("isTourQuest");
--
local curQuestLife = nil;
local curQuestMaxTimeMin = nil;

local function onQuestStart()
	local QuestManager = Constants:get_QuestManager();
	local isTourQuest = isTourQuest_method:call(QuestManager);

	if curQuestLife == nil then
		curQuestLife = isTourQuest == true and "제한 없음" or Constants:getQuestLife();
	end

	this.DeathCount = string_format("다운 횟수: %d / %s", Constants:getDeathNum(), curQuestLife);

	curQuestMaxTimeMin = (isTourQuest == true or isQuestMaxTimeUnlimited_method:call(QuestManager) == true) and "제한 없음" or tostring(getQuestMaxTimeMin_method:call(QuestManager)) .. "분";
	this.QuestTimer = string_format("%s / %s", getClearTimeFormatText_method:call(nil, getQuestElapsedTimeSec_method:call(QuestManager)), curQuestMaxTimeMin);

	this.QuestInfoDataCreated = true;
end

local function updateDeathCount()
	if this.QuestInfoDataCreated == true then
		this.DeathCount = string_format("다운 횟수: %d / %s", Constants:getDeathNum(), curQuestLife);
	end
end

local function updateQuestTimer()
	if this.QuestInfoDataCreated == true then
		this.QuestTimer = string_format("%s / %s", getClearTimeFormatText_method:call(nil, getQuestElapsedTimeSec_method:call(Constants:get_QuestManager())), curQuestMaxTimeMin);
	end
end

local function Terminate()
	this.QuestInfoDataCreated = false;
	this.QuestTimer = nil;
	this.DeathCount = nil;
	curQuestLife = nil;
	curQuestMaxTimeMin = nil;
end

this.init = function()
	if Constants:checkGameStatus(2) == true then
		onQuestStart();
	end

	hook(QuestManager_type_def:get_method("questForfeit(System.Int32, System.UInt32)"), nil, updateDeathCount);
	hook(QuestManager_type_def:get_method("updateQuestTime"), nil, updateQuestTimer);
	hook(QuestManager_type_def:get_method("onQuestEnd"), nil, Terminate);
end
this.onQuestStart = onQuestStart;
--
return this;