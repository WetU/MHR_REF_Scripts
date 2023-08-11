local Constants = _G.require("Constants.Constants");

local tostring = Constants.lua.tostring;
local string_format = Constants.lua.string_format;

local find_type_definition = Constants.sdk.find_type_definition;
local get_managed_singleton = Constants.sdk.get_managed_singleton;
local to_managed_object = Constants.sdk.to_managed_object;
local hook = Constants.sdk.hook;

local checkGameStatus = Constants.checkGameStatus;
local getQuestLife = Constants.getQuestLife;
local getDeathNum = Constants.getDeathNum;
--
local this = {
	init = true,
	onQuestStart = true,
	QuestTimer = nil,
	DeathCount = nil
};
--
local QuestManager_type_def = Constants.type_definitions.QuestManager_type_def;
local getQuestMaxTimeMin_method = QuestManager_type_def:get_method("getQuestMaxTimeMin");
local isQuestMaxTimeUnlimited_method = QuestManager_type_def:get_method("isQuestMaxTimeUnlimited");
local getQuestElapsedTimeSec_method = QuestManager_type_def:get_method("getQuestElapsedTimeSec");
local isTourQuest_method = QuestManager_type_def:get_method("isTourQuest");
--
local getClearTimeFormatText_method = find_type_definition("snow.gui.SnowGuiCommonUtility"):get_method("getClearTimeFormatText(System.Single)"); -- static
--
local isTourQuest = false;
local curQuestLife = nil;
local curQuestMaxTimeMin = nil;

local function updateDeathCount(questManager)
	if curQuestLife == nil then
		curQuestLife = isTourQuest == true and "제한 없음" or getQuestLife(questManager);
	end

	this.DeathCount = string_format("다운 횟수: %d / %s", getDeathNum(questManager), curQuestLife);
end

local function updateQuestTimer(questManager)
	this.QuestTimer = string_format("%s / %s", getClearTimeFormatText_method:call(nil, getQuestElapsedTimeSec_method:call(questManager)), curQuestMaxTimeMin);
end

local function onQuestStart()
	local QuestManager = get_managed_singleton("snow.QuestManager");
	isTourQuest = isTourQuest_method:call(QuestManager);
	updateDeathCount(QuestManager);

	curQuestMaxTimeMin = (isTourQuest == true or isQuestMaxTimeUnlimited_method:call(QuestManager) == true) and "제한 없음" or tostring(getQuestMaxTimeMin_method:call(QuestManager)) .. "분";
	updateQuestTimer(QuestManager);
end

local PreHook_questForfeit = nil;
local PostHook_questForfeit = nil;
do
	local QuestManager = nil;
	PreHook_questForfeit = function(args)
		QuestManager = to_managed_object(args[2]) or get_managed_singleton("snow.QuestManager");
	end
	PostHook_questForfeit = function()
		updateDeathCount(QuestManager);
		QuestManager = nil;
	end
end

local function PreHook_updateQuestTime(args)
	updateQuestTimer(to_managed_object(args[2]) or get_managed_singleton("snow.QuestManager"));
end

local function Terminate()
	this.QuestTimer = nil;
	this.DeathCount = nil;
	isTourQuest = false;
	curQuestLife = nil;
	curQuestMaxTimeMin = nil;
end

local function init()
	if checkGameStatus(Constants.GameStatusType.Quest) == true then
		onQuestStart();
	end
	hook(QuestManager_type_def:get_method("questForfeit(System.Int32, System.UInt32)"), PreHook_questForfeit, PostHook_questForfeit);
	hook(QuestManager_type_def:get_method("updateQuestTime"), PreHook_updateQuestTime);
	hook(QuestManager_type_def:get_method("onQuestEnd"), nil, Terminate);
end

this.init = init;
this.onQuestStart = onQuestStart;
--
return this;