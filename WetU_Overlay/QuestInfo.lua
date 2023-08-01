local Constants = require("Constants.Constants");
--
local this = {
    QuestTimer = nil,
    DeathCount = nil
};
--
local getQuestMaxTimeMin_method = Constants.type_definitions.QuestManager_type_def:get_method("getQuestMaxTimeMin");
local isQuestMaxTimeUnlimited_method = Constants.type_definitions.QuestManager_type_def:get_method("isQuestMaxTimeUnlimited");
local getQuestElapsedTimeSec_method = Constants.type_definitions.QuestManager_type_def:get_method("getQuestElapsedTimeSec");
local isTourQuest_method = Constants.type_definitions.QuestManager_type_def:get_method("isTourQuest");
--
local getClearTimeFormatText_method = sdk.find_type_definition("snow.gui.SnowGuiCommonUtility"):get_method("getClearTimeFormatText(System.Single)"); -- static
--
local isTourQuest = false;
local curQuestLife = nil;
local curQuestMaxTimeMin = nil;

local function Terminate()
    this.QuestTimer = nil;
    this.DeathCount = nil;
    isTourQuest = false;
    curQuestLife = nil;
    curQuestMaxTimeMin = nil;
end

local function updateDeathCount(questManager)
    if curQuestLife == nil then
        curQuestLife = isTourQuest == true and "제한 없음" or Constants.getQuestLife(questManager);
    end

    this.DeathCount = string.format("다운 횟수: %d / %s", Constants.getDeathNum(questManager), curQuestLife);
end

function this.onQuestStart()
    local QuestManager = sdk.get_managed_singleton("snow.QuestManager");
    isTourQuest = isTourQuest_method:call(QuestManager);
    updateDeathCount(QuestManager);

    local QuestElapsedTimeSec = getQuestElapsedTimeSec_method:call(QuestManager);
    curQuestMaxTimeMin = (isTourQuest == true or isQuestMaxTimeUnlimited_method:call(QuestManager) == true) and "제한 없음" or tostring(getQuestMaxTimeMin_method:call(QuestManager)) .. "분";
    this.QuestTimer = string.format("%s / %s", getClearTimeFormatText_method:call(nil, QuestElapsedTimeSec), curQuestMaxTimeMin);
end

local PreHook_questForfeit = nil;
local PostHook_questForfeit = nil;
do
    local QuestManager = nil;
    function PreHook_questForfeit(args)
        QuestManager = sdk.to_managed_object(args[2]) or sdk.get_managed_singleton("snow.QuestManager");
    end
    function PostHook_questForfeit()
        updateDeathCount(QuestManager);
        QuestManager = nil;
    end
end

local function PreHook_updateQuestTime(args)
    local QuestElapsedTimeSec = getQuestElapsedTimeSec_method:call(sdk.to_managed_object(args[2]) or sdk.get_managed_singleton("snow.QuestManager"));
    this.QuestTimer = string.format("%s / %s", getClearTimeFormatText_method:call(nil, QuestElapsedTimeSec), curQuestMaxTimeMin);
end

function this.init()
    sdk.hook(Constants.type_definitions.QuestManager_type_def:get_method("questForfeit(System.Int32, System.UInt32)"), PreHook_questForfeit, PostHook_questForfeit);
    sdk.hook(Constants.type_definitions.QuestManager_type_def:get_method("updateQuestTime"), PreHook_updateQuestTime);
    sdk.hook(Constants.type_definitions.QuestManager_type_def:get_method("onQuestEnd"), nil, Terminate);
end
--
return this;