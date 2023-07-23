local Constants = require("Constants.Constants");
if Constants == nil then
    return;
end
--
local this = {
    QuestTimer = nil,
    DeathCount = nil
};
--
local getQuestLife_method = Constants.type_definitions.QuestManager_type_def:get_method("getQuestLife");
local getDeathNum_method = Constants.type_definitions.QuestManager_type_def:get_method("getDeathNum");

local getQuestMaxTimeMin_method = Constants.type_definitions.QuestManager_type_def:get_method("getQuestMaxTimeMin");
local isQuestMaxTimeUnlimited_method = Constants.type_definitions.QuestManager_type_def:get_method("isQuestMaxTimeUnlimited");
local getQuestElapsedTimeSec_method = Constants.type_definitions.QuestManager_type_def:get_method("getQuestElapsedTimeSec");
local getQuestElapsedTimeMin_method = Constants.type_definitions.QuestManager_type_def:get_method("getQuestElapsedTimeMin");
--
local getClearTimeFormatText_method = Constants.SDK.find_type_definition("snow.gui.SnowGuiCommonUtility"):get_method("getClearTimeFormatText(System.Single)"); -- static
--
local curQuestLife = nil;
local curQuestMaxTimeMin = nil;

local function Terminate()
    this.QuestTimer = nil;
    this.DeathCount = nil;
    curQuestLife = nil;
    curQuestMaxTimeMin = nil;
end

local function getCurrentQuestLife(questManager)
    if questManager == nil then
        questManager = Constants.SDK.get_managed_singleton("snow.QuestManager");
        if questManager == nil then
            return;
        end
    end

    curQuestLife = getQuestLife_method:call(questManager);
end

local function updateDeathCount(questManager)
    if questManager == nil then
        questManager = Constants.SDK.get_managed_singleton("snow.QuestManager");
        if questManager == nil then
            return;
        end
    end

    if curQuestLife == nil then
        getCurrentQuestLife(questManager);
    end

    this.DeathCount = Constants.LUA.string_format("다운 횟수: %d / %d", getDeathNum_method:call(questManager), curQuestLife);
end

local function onQuestStart()
    local QuestManager = Constants.SDK.get_managed_singleton("snow.QuestManager");
    if QuestManager ~= nil then
        updateDeathCount(QuestManager);

        local QuestElapsedTimeSec = getQuestElapsedTimeSec_method:call(QuestManager);
        local QuestElapsedTimeMin = getQuestElapsedTimeMin_method:call(QuestManager);

        if isQuestMaxTimeUnlimited_method:call(QuestManager) == false then
            curQuestMaxTimeMin = getQuestMaxTimeMin_method:call(QuestManager);
            this.QuestTimer = getClearTimeFormatText_method:call(nil, QuestElapsedTimeSec) .. " / " .. Constants.LUA.string_format("%d분", curQuestMaxTimeMin);
        else
            curQuestMaxTimeMin = nil;
            this.QuestTimer = getClearTimeFormatText_method:call(nil, QuestElapsedTimeSec);
        end

        return;
    end

    Terminate();
end

local QuestManager = nil;
local function PreHook_questForfeit(args)
    QuestManager = Constants.SDK.to_managed_object(args[2]);
end
local function PostHook_questForfeit()
    if QuestManager == nil then
        QuestManager = Constants.SDK.get_managed_singleton("snow.QuestManager");
        if QuestManager == nil then
            return;
        end
    end

    updateDeathCount(QuestManager);
    QuestManager = nil;
end

local function PreHook_updateQuestTime(args)
    local QuestManager = Constants.SDK.to_managed_object(args[2]);
    if QuestManager == nil then
        QuestManager = Constants.SDK.get_managed_singleton("snow.QuestManager");
        if QuestManager == nil then
            return;
        end
    end

    local QuestElapsedTimeSec = getQuestElapsedTimeSec_method:call(QuestManager);
    local QuestElapsedTimeMin = getQuestElapsedTimeMin_method:call(QuestManager);
    this.QuestTimer = curQuestMaxTimeMin ~= nil
        and getClearTimeFormatText_method:call(nil, QuestElapsedTimeSec) .. " / " .. Constants.LUA.string_format("%d분", curQuestMaxTimeMin)
        or getClearTimeFormatText_method:call(nil, QuestElapsedTimeSec);
end

function this.init()
    if Constants.checkGameStatus(Constants.GameStatusType.Quest) == true then
        onQuestStart();
    end
    Constants.SDK.hook(Constants.type_definitions.WwiseChangeSpaceWatcher_type_def:get_method("onQuestStart"), nil, onQuestStart);
    Constants.SDK.hook(Constants.type_definitions.QuestManager_type_def:get_method("questForfeit(System.Int32, System.UInt32)"), PreHook_questForfeit, PostHook_questForfeit);
    Constants.SDK.hook(Constants.type_definitions.QuestManager_type_def:get_method("updateQuestTime"), PreHook_updateQuestTime);
    Constants.SDK.hook(Constants.type_definitions.QuestManager_type_def:get_method("onQuestEnd"), nil, Terminate);
end
--
return this;