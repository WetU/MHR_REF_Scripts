local Constants = require("Constants.Constants");
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

local function updateDeathCount(questManager)
    if questManager == nil then
        questManager = Constants.SDK.get_managed_singleton("snow.QuestManager");
    end

    if curQuestLife == nil then
        curQuestLife = getQuestLife_method:call(questManager);
    end

    this.DeathCount = Constants.LUA.string_format("다운 횟수: %d / %d", getDeathNum_method:call(questManager), curQuestLife);
end

function this.onQuestStart()
    local QuestManager = Constants.SDK.get_managed_singleton("snow.QuestManager");
    updateDeathCount(QuestManager);

    local QuestElapsedTimeSec = getQuestElapsedTimeSec_method:call(QuestManager);

    if isQuestMaxTimeUnlimited_method:call(QuestManager) == false then
        curQuestMaxTimeMin = getQuestMaxTimeMin_method:call(QuestManager);
        this.QuestTimer = getClearTimeFormatText_method:call(nil, QuestElapsedTimeSec) .. " / " .. Constants.LUA.string_format("%d분", curQuestMaxTimeMin);
    else
        curQuestMaxTimeMin = nil;
        this.QuestTimer = getClearTimeFormatText_method:call(nil, QuestElapsedTimeSec);
    end
end

local QuestManager_forfeit = nil;
local function PreHook_questForfeit(args)
    QuestManager_forfeit = Constants.SDK.to_managed_object(args[2]) or Constants.SDK.get_managed_singleton("snow.QuestManager");
end
local function PostHook_questForfeit()
    updateDeathCount(QuestManager_forfeit);
    QuestManager_forfeit = nil;
end

local function PreHook_updateQuestTime(args)
    local QuestElapsedTimeSec = getQuestElapsedTimeSec_method:call(Constants.SDK.to_managed_object(args[2]) or Constants.SDK.get_managed_singleton("snow.QuestManager"));
    this.QuestTimer = curQuestMaxTimeMin ~= nil
        and getClearTimeFormatText_method:call(nil, QuestElapsedTimeSec) .. " / " .. Constants.LUA.string_format("%d분", curQuestMaxTimeMin)
        or getClearTimeFormatText_method:call(nil, QuestElapsedTimeSec);
end

function this.init()
    Constants.SDK.hook(Constants.type_definitions.QuestManager_type_def:get_method("questForfeit(System.Int32, System.UInt32)"), PreHook_questForfeit, PostHook_questForfeit);
    Constants.SDK.hook(Constants.type_definitions.QuestManager_type_def:get_method("updateQuestTime"), PreHook_updateQuestTime);
    Constants.SDK.hook(Constants.type_definitions.QuestManager_type_def:get_method("onQuestEnd"), nil, Terminate);
end
--
return this;