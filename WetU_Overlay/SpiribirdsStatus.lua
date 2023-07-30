local Constants = require("Constants.Constants");
--
local this = {
    SpiribirdsHudDataCreated = nil,
    SpiribirdsCall_Timer = nil,
    StatusBuffLimits = nil,
    AcquiredValues = nil,
    BirdsMaxCounts = nil,
    AcquiredCounts = nil,
    Buffs = {
        "Atk",
        "Def",
        "Vital",
        "Stamina"
    },
    LocalizedBirdTypes = {
        "공격력",
        "방어력",
        "체력",
        "스태미나"
    },
    BirdTypeToColor = {
        4278190335,
        4278222847,
        4278222848,
        4278255615
    }
};
--
local calcLvBuffNumToMax_method = Constants.type_definitions.EquipDataManager_type_def:get_method("calcLvBuffNumToMax(snow.player.PlayerDefine.LvBuff)");
local addLvBuffCount_method = Constants.type_definitions.EquipDataManager_type_def:get_method("addLvBuffCount(snow.data.NormalLvBuffCageData.BuffTypes, System.Int32)"); -- static
local calcLvBuffValue_method = Constants.type_definitions.EquipDataManager_type_def:get_method("calcLvBuffValue(snow.data.NormalLvBuffCageData.BuffTypes)");
local getEquippingLvBuffcageData_method = Constants.type_definitions.EquipDataManager_type_def:get_method("getEquippingLvBuffcageData");

local getStatusBuffLimit_method = getEquippingLvBuffcageData_method:get_return_type():get_method("getStatusBuffLimit(snow.data.NormalLvBuffCageData.BuffTypes)");

local getLvBuffCnt_method = Constants.type_definitions.PlayerManager_type_def:get_method("getLvBuffCnt(snow.player.PlayerDefine.LvBuff)");
--
local PlayerQuestBase_type_def = sdk.find_type_definition("snow.player.PlayerQuestBase");
local get_IsInTrainingArea_method = PlayerQuestBase_type_def:get_method("get_IsInTrainingArea");
local IsEnableStage_Skill211_field = PlayerQuestBase_type_def:get_field("_IsEnableStage_Skill211");

local PlayerBase_type_def = PlayerQuestBase_type_def:get_parent_type();
local isMasterPlayer_method = PlayerBase_type_def:get_method("isMasterPlayer");
local get_PlayerData_method = PlayerBase_type_def:get_method("get_PlayerData");

local SpiribirdsCallTimer_field = get_PlayerData_method:get_return_type():get_field("_EquipSkill211_Timer");
--
local LvBuff_type_def = sdk.find_type_definition("snow.player.PlayerDefine.LvBuff");
local LvBuff = {
    ["Atk"] = LvBuff_type_def:get_field("Attack"):get_data(nil),
    ["Def"] = LvBuff_type_def:get_field("Defence"):get_data(nil),
    ["Vital"] = LvBuff_type_def:get_field("Vital"):get_data(nil),
    ["Stamina"] = LvBuff_type_def:get_field("Stamina"):get_data(nil),
    ["Rainbow"] = LvBuff_type_def:get_field("Rainbow"):get_data(nil)
};
--
local NormalLvBuffCageData_BuffTypes_type_def = sdk.find_type_definition("snow.data.NormalLvBuffCageData.BuffTypes");
local BuffTypes = {};
for _, v in ipairs(this.Buffs) do
    BuffTypes[v] = NormalLvBuffCageData_BuffTypes_type_def:get_field(v):get_data(nil);
end
--
local hasRainbow = false;
local firstHook = true;
local skipUpdate = false;

local function Terminate()
    this.SpiribirdsHudDataCreated = nil;
    this.SpiribirdsCall_Timer = nil;
    this.StatusBuffLimits = nil;
    this.AcquiredValues = nil;
    this.BirdsMaxCounts = nil;
    this.AcquiredCounts = nil;
    hasRainbow = false;
    firstHook = true;
    skipUpdate = false;
end

function this.CreateData()
    local PlayerManager = sdk.get_managed_singleton("snow.player.PlayerManager");
    hasRainbow = getLvBuffCnt_method:call(PlayerManager, LvBuff.Rainbow) > 0;

    local EquipDataManager = sdk.get_managed_singleton("snow.data.EquipDataManager");
    local EquippingLvBuffcageData = getEquippingLvBuffcageData_method:call(EquipDataManager);

    this.StatusBuffLimits = {};
    this.BirdsMaxCounts = {};
    this.AcquiredCounts = {};
    this.AcquiredValues = {};

    for k, v in pairs(BuffTypes) do
        local StatusBuffLimit = getStatusBuffLimit_method:call(EquippingLvBuffcageData, v);
        local LvBuffNumToMax = calcLvBuffNumToMax_method:call(EquipDataManager, LvBuff[k]);
        this.StatusBuffLimits[k] = StatusBuffLimit;
        this.BirdsMaxCounts[k] = LvBuffNumToMax;
        this.AcquiredCounts[k] = hasRainbow == true and LvBuffNumToMax or math.min(math.max(getLvBuffCnt_method:call(PlayerManager, LvBuff[k]), 0), LvBuffNumToMax);
        this.AcquiredValues[k] = hasRainbow == true and StatusBuffLimit or math.min(math.max(calcLvBuffValue_method:call(EquipDataManager, v), 0), StatusBuffLimit);
    end

    this.SpiribirdsHudDataCreated = true;
end

local function getBuffParameters(equipDataManager, playerManager, buffType)
    for k, v in pairs(LvBuff) do
        if buffType == v then
            this.AcquiredCounts[k] = math.min(math.max(getLvBuffCnt_method:call(playerManager, v), 0), this.BirdsMaxCounts[k]);
            this.AcquiredValues[k] = math.min(math.max(calcLvBuffValue_method:call(equipDataManager, BuffTypes[k]), 0), this.StatusBuffLimits[k]);
            break;
        end
    end
end

local function getCallTimer(playerQuestBase)
    this.SpiribirdsCall_Timer = string.format("향응 타이머: %.f초", 60.0 - (SpiribirdsCallTimer_field:get_data(get_PlayerData_method:call(playerQuestBase)) / 60.0));
end

function this.onQuestStart()
    if this.SpiribirdsHudDataCreated ~= true then
        this.CreateData();
    end

    local MapNo = Constants.getQuestMapNo(nil);

    for _, map in pairs(Constants.QuestMapList) do
        if map == MapNo then
            for k, v in pairs(BuffTypes) do
                addLvBuffCount_method:call(nil, v, this.BirdsMaxCounts[k]);
            end
            break;
        end
    end
end

local PlayerQuestBase_start = nil;
local function PreHook_PlayerQuestBase_start(args)
    PlayerQuestBase_start = sdk.to_managed_object(args[2]);
end
local function PostHook_PlayerQuestBase_start()
    if isMasterPlayer_method:call(PlayerQuestBase_start) == true then
        this.CreateData();
    end

    PlayerQuestBase_start = nil;
end

local subBuffType = nil;
local function PreHook_subLvBuffFromEnemy(args)
    if isMasterPlayer_method:call(sdk.to_managed_object(args[2])) == true then
        if this.SpiribirdsHudDataCreated ~= true then
            this.CreateData();
        end

        subBuffType = sdk.to_int64(args[3]);
    end
end
local function PostHook_subLvBuffFromEnemy(retval)
    if subBuffType ~= nil and Constants.to_bool(retval) == true then
        if subBuffType == LvBuff.Rainbow then
            hasRainbow = false;

            for _, v in ipairs(this.Buffs) do
                this.AcquiredCounts[v] = 0;
                this.AcquiredValues[v] = 0;
            end
        else
            getBuffParameters(sdk.get_managed_singleton("snow.data.EquipDataManager"), sdk.get_managed_singleton("snow.player.PlayerManager"), subBuffType)
        end
    end

    subBuffType = nil;
    return retval;
end

local function PreHook_updateEquipSkill211(args)
    if firstHook == true or skipUpdate ~= true then
        local PlayerQuestBase = sdk.to_managed_object(args[2]);

        if isMasterPlayer_method:call(PlayerQuestBase) == true then
            if firstHook == true then
                firstHook = false;

                if get_IsInTrainingArea_method:call(PlayerQuestBase) == true or IsEnableStage_Skill211_field:get_data(PlayerQuestBase) ~= true then
                    skipUpdate = true;
                    this.SpiribirdsCall_Timer = "향응 비활성 지역";
                end
            else
                getCallTimer(PlayerQuestBase);
            end
        end
    end
end

local addBuffType = nil;
local PlayerManager_obj = nil;
local function PreHook_addLvBuffCnt(args)
    if this.SpiribirdsHudDataCreated ~= true then
        this.CreateData();
    end

    addBuffType = sdk.to_int64(args[4]);

    if addBuffType == LvBuff.Rainbow then
        hasRainbow = true;
        addBuffType = nil;
    else
        PlayerManager_obj = sdk.to_managed_object(args[2]) or sdk.get_managed_singleton("snow.player.PlayerManager");
    end
end
local function PostHook_addLvBuffCnt()
    if hasRainbow == true then
        for k, v in pairs(this.StatusBuffLimits) do
            this.AcquiredCounts[k] = this.BirdsMaxCounts[k];
            this.AcquiredValues[k] = v;
        end

    elseif addBuffType ~= nil then
        getBuffParameters(sdk.get_managed_singleton("snow.data.EquipDataManager"), PlayerManager_obj, addBuffType);
    end

    addBuffType = nil;
    PlayerManager_obj = nil;
end

function this.init()
    sdk.hook(PlayerQuestBase_type_def:get_method("start"), PreHook_PlayerQuestBase_start, PostHook_PlayerQuestBase_start);
    sdk.hook(PlayerQuestBase_type_def:get_method("subLvBuffFromEnemy(snow.player.PlayerDefine.LvBuff, System.Int32)"), PreHook_subLvBuffFromEnemy, PostHook_subLvBuffFromEnemy);
    sdk.hook(PlayerQuestBase_type_def:get_method("updateEquipSkill211"), PreHook_updateEquipSkill211);
    sdk.hook(Constants.type_definitions.PlayerManager_type_def:get_method("addLvBuffCnt(System.Int32, snow.player.PlayerDefine.LvBuff)"), PreHook_addLvBuffCnt, PostHook_addLvBuffCnt);
    sdk.hook(Constants.type_definitions.PlayerManager_type_def:get_method("clearLvBuffCnt"), nil, Terminate);
end
--
return this;