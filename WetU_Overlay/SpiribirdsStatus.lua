local Constants = _G.require("Constants.Constants");

local pairs = Constants.lua.pairs;
local ipairs = Constants.lua.ipairs;

local math_min = Constants.lua.math_min;
local math_max = Constants.lua.math_max;

local string_format = Constants.lua.string_format;

local find_type_definition = Constants.sdk.find_type_definition;
local get_managed_singleton = Constants.sdk.get_managed_singleton;
local to_managed_object = Constants.sdk.to_managed_object;
local hook = Constants.sdk.hook;
local to_int64 = Constants.sdk.to_int64;

local getQuestMapNo = Constants.getQuestMapNo;
local QuestMapList = Constants.QuestMapList;
local to_bool = Constants.to_bool;
--
local this = {
    init = true,
    CreateData = true,
    onQuestStart = true,

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
local EquipDataManager_type_def = Constants.type_definitions.EquipDataManager_type_def;
local calcLvBuffNumToMax_method = EquipDataManager_type_def:get_method("calcLvBuffNumToMax(snow.player.PlayerDefine.LvBuff)");
local addLvBuffCount_method = EquipDataManager_type_def:get_method("addLvBuffCount(snow.data.NormalLvBuffCageData.BuffTypes, System.Int32)"); -- static
local calcLvBuffValue_method = EquipDataManager_type_def:get_method("calcLvBuffValue(snow.data.NormalLvBuffCageData.BuffTypes)");
local getEquippingLvBuffcageData_method = EquipDataManager_type_def:get_method("getEquippingLvBuffcageData");

local getStatusBuffLimit_method = getEquippingLvBuffcageData_method:get_return_type():get_method("getStatusBuffLimit(snow.data.NormalLvBuffCageData.BuffTypes)");
--
local PlayerManager_type_def = Constants.type_definitions.PlayerManager_type_def;
local getLvBuffCnt_method = PlayerManager_type_def:get_method("getLvBuffCnt(snow.player.PlayerDefine.LvBuff)");
--
local PlayerQuestBase_type_def = find_type_definition("snow.player.PlayerQuestBase");
local get_IsInTrainingArea_method = PlayerQuestBase_type_def:get_method("get_IsInTrainingArea");
local IsEnableStage_Skill211_field = PlayerQuestBase_type_def:get_field("_IsEnableStage_Skill211");

local PlayerBase_type_def = PlayerQuestBase_type_def:get_parent_type();
local isMasterPlayer_method = PlayerBase_type_def:get_method("isMasterPlayer");
local get_PlayerData_method = PlayerBase_type_def:get_method("get_PlayerData");

local SpiribirdsCallTimer_field = get_PlayerData_method:get_return_type():get_field("_EquipSkill211_Timer");
--
local LvBuff_type_def = find_type_definition("snow.player.PlayerDefine.LvBuff");
local LvBuff = {
    Atk = LvBuff_type_def:get_field("Attack"):get_data(nil),
    Def = LvBuff_type_def:get_field("Defence"):get_data(nil),
    Vital = LvBuff_type_def:get_field("Vital"):get_data(nil),
    Stamina = LvBuff_type_def:get_field("Stamina"):get_data(nil),
    Rainbow = LvBuff_type_def:get_field("Rainbow"):get_data(nil)
};
--
local NormalLvBuffCageData_BuffTypes_type_def = find_type_definition("snow.data.NormalLvBuffCageData.BuffTypes");
local BuffTypes = {
    Atk = NormalLvBuffCageData_BuffTypes_type_def:get_field("Atk"):get_data(nil),
    Def = NormalLvBuffCageData_BuffTypes_type_def:get_field("Def"):get_data(nil),
    Vital = NormalLvBuffCageData_BuffTypes_type_def:get_field("Vital"):get_data(nil),
    Stamina = NormalLvBuffCageData_BuffTypes_type_def:get_field("Stamina"):get_data(nil)
};
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

local function mkTable()
    local table = {
        Atk = true,
        Def = true,
        Vital = true,
        Stamina = true
    };

    return table;
end

local function createData()
    local PlayerManager = get_managed_singleton("snow.player.PlayerManager");
    hasRainbow = getLvBuffCnt_method:call(PlayerManager, LvBuff.Rainbow) > 0;

    local EquipDataManager = get_managed_singleton("snow.data.EquipDataManager");
    local EquippingLvBuffcageData = getEquippingLvBuffcageData_method:call(EquipDataManager);

    this.StatusBuffLimits = mkTable();
    this.BirdsMaxCounts = mkTable();
    this.AcquiredCounts = mkTable();
    this.AcquiredValues = mkTable();

    for k, v in pairs(BuffTypes) do
        local LvBuffType = LvBuff[k];
        local StatusBuffLimit = getStatusBuffLimit_method:call(EquippingLvBuffcageData, v);
        local LvBuffNumToMax = calcLvBuffNumToMax_method:call(EquipDataManager, LvBuffType);
        this.StatusBuffLimits[k] = StatusBuffLimit;
        this.BirdsMaxCounts[k] = LvBuffNumToMax;
        this.AcquiredCounts[k] = hasRainbow == true and LvBuffNumToMax or math_min(math_max(getLvBuffCnt_method:call(PlayerManager, LvBuffType), 0), LvBuffNumToMax);
        this.AcquiredValues[k] = hasRainbow == true and StatusBuffLimit or math_min(math_max(calcLvBuffValue_method:call(EquipDataManager, v), 0), StatusBuffLimit);
    end

    this.SpiribirdsHudDataCreated = true;
end

this.CreateData = createData;

local function getBuffParameters(equipDataManager, playerManager, buffType)
    for k, v in pairs(LvBuff) do
        if buffType == v then
            this.AcquiredCounts[k] = math_min(math_max(getLvBuffCnt_method:call(playerManager, v), 0), this.BirdsMaxCounts[k]);
            this.AcquiredValues[k] = math_min(math_max(calcLvBuffValue_method:call(equipDataManager, BuffTypes[k]), 0), this.StatusBuffLimits[k]);
            break;
        end
    end
end

local function getCallTimer(playerQuestBase)
    this.SpiribirdsCall_Timer = string_format("향응 타이머: %.f초", 60.0 - (SpiribirdsCallTimer_field:get_data(get_PlayerData_method:call(playerQuestBase)) / 60.0));
end

local function onQuestStart()
    if this.SpiribirdsHudDataCreated ~= true then
        createData();
    end

    local MapNo = getQuestMapNo(nil);

    for _, map in pairs(QuestMapList) do
        if map == MapNo then
            for k, v in pairs(BuffTypes) do
                addLvBuffCount_method:call(nil, v, this.BirdsMaxCounts[k]);
            end
            break;
        end
    end
end

this.onQuestStart = onQuestStart;

local PreHook_PlayerQuestBase_start = nil;
local PostHook_PlayerQuestBase_start = nil;
do
    local PlayerQuestBase = nil;
    PreHook_PlayerQuestBase_start = function(args)
        PlayerQuestBase = to_managed_object(args[2]);
    end
    PostHook_PlayerQuestBase_start = function()
        if isMasterPlayer_method:call(PlayerQuestBase) == true then
            createData();
        end

        PlayerQuestBase = nil;
    end
end

local subBuffType = nil;
local function PreHook_subLvBuffFromEnemy(args)
    if isMasterPlayer_method:call(to_managed_object(args[2])) == true then
        if this.SpiribirdsHudDataCreated ~= true then
            createData();
        end

        subBuffType = to_int64(args[3]);
    end
end
local function PostHook_subLvBuffFromEnemy(retval)
    if subBuffType ~= nil and to_bool(retval) == true then
        if subBuffType == LvBuff.Rainbow then
            hasRainbow = false;

            for _, v in ipairs(this.Buffs) do
                this.AcquiredCounts[v] = 0;
                this.AcquiredValues[v] = 0;
            end
        else
            getBuffParameters(get_managed_singleton("snow.data.EquipDataManager"), get_managed_singleton("snow.player.PlayerManager"), subBuffType)
        end
    end

    subBuffType = nil;
    return retval;
end

local function PreHook_updateEquipSkill211(args)
    if firstHook == true or skipUpdate ~= true then
        local PlayerQuestBase = to_managed_object(args[2]);

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

local PreHook_addLvBuffCnt = nil;
local PostHook_addLvBuffCnt = nil;
do
    local addBuffType = nil;
    local PlayerManager = nil;
    PreHook_addLvBuffCnt = function(args)
        if this.SpiribirdsHudDataCreated ~= true then
            createData();
        end

        local buffType = to_int64(args[4]);

        if buffType == LvBuff.Rainbow then
            hasRainbow = true;
        else
            addBuffType = buffType;
            PlayerManager = to_managed_object(args[2]) or get_managed_singleton("snow.player.PlayerManager");
        end
    end
    PostHook_addLvBuffCnt = function()
        if hasRainbow == true then
            for k, v in pairs(this.StatusBuffLimits) do
                this.AcquiredCounts[k] = this.BirdsMaxCounts[k];
                this.AcquiredValues[k] = v;
            end

        elseif addBuffType ~= nil then
            getBuffParameters(get_managed_singleton("snow.data.EquipDataManager"), PlayerManager, addBuffType);
        end

        addBuffType = nil;
        PlayerManager = nil;
    end
end

local function init()
    hook(PlayerQuestBase_type_def:get_method("start"), PreHook_PlayerQuestBase_start, PostHook_PlayerQuestBase_start);
    hook(PlayerQuestBase_type_def:get_method("subLvBuffFromEnemy(snow.player.PlayerDefine.LvBuff, System.Int32)"), PreHook_subLvBuffFromEnemy, PostHook_subLvBuffFromEnemy);
    hook(PlayerQuestBase_type_def:get_method("updateEquipSkill211"), PreHook_updateEquipSkill211);
    hook(PlayerManager_type_def:get_method("addLvBuffCnt(System.Int32, snow.player.PlayerDefine.LvBuff)"), PreHook_addLvBuffCnt, PostHook_addLvBuffCnt);
    hook(PlayerManager_type_def:get_method("clearLvBuffCnt"), nil, Terminate);
end

this.init = init;
    
--
return this;