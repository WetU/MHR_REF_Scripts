local Constants = require("Constants.Constants");
if Constants == nil then
	return;
end
--
local this = {
    SpiribirdsHudDataCreated = nil,
    SpiribirdsCall_Timer = nil,
    StatusBuffLimits = nil,
    AcquiredValues = nil,
    BirdsMaxCounts = nil,
    AcquiredCounts = nil
};
--
local calcLvBuffNumToMax_method = Constants.type_definitions.EquipDataManager_type_def:get_method("calcLvBuffNumToMax(snow.player.PlayerDefine.LvBuff)");
local addLvBuffCount_method = Constants.type_definitions.EquipDataManager_type_def:get_method("addLvBuffCount(snow.data.NormalLvBuffCageData.BuffTypes, System.Int32)"); -- static
local calcLvBuffValue_method = Constants.type_definitions.EquipDataManager_type_def:get_method("calcLvBuffValue(snow.data.NormalLvBuffCageData.BuffTypes)");
local getEquippingLvBuffcageData_method = Constants.type_definitions.EquipDataManager_type_def:get_method("getEquippingLvBuffcageData");

local getStatusBuffLimit_method = getEquippingLvBuffcageData_method:get_return_type():get_method("getStatusBuffLimit(snow.data.NormalLvBuffCageData.BuffTypes)");

local getLvBuffCnt_method = Constants.type_definitions.PlayerManager_type_def:get_method("getLvBuffCnt(snow.player.PlayerDefine.LvBuff)");

local PlayerQuestBase_type_def = Constants.SDK.find_type_definition("snow.player.PlayerQuestBase");
local onDestroy_method = PlayerQuestBase_type_def:get_method("onDestroy");
local get_IsInTrainingArea_method = PlayerQuestBase_type_def:get_method("get_IsInTrainingArea");
local IsEnableStage_Skill211_field = PlayerQuestBase_type_def:get_field("_IsEnableStage_Skill211");

local PlayerBase_type_def = PlayerQuestBase_type_def:get_parent_type();
local isMasterPlayer_method = PlayerBase_type_def:get_method("isMasterPlayer");
local getPlayerIndex_method = PlayerBase_type_def:get_method("getPlayerIndex");
local get_PlayerData_method = PlayerBase_type_def:get_method("get_PlayerData");

local SpiribirdsCallTimer_field = get_PlayerData_method:get_return_type():get_field("_EquipSkill211_Timer");
--
local LvBuff_type_def = Constants.SDK.find_type_definition("snow.player.PlayerDefine.LvBuff");
local LvBuff = {
    ["Atk"] = LvBuff_type_def:get_field("Attack"):get_data(nil),
    ["Def"] = LvBuff_type_def:get_field("Defence"):get_data(nil),
    ["Vital"] = LvBuff_type_def:get_field("Vital"):get_data(nil),
    ["Stamina"] = LvBuff_type_def:get_field("Stamina"):get_data(nil),
    ["Rainbow"] = LvBuff_type_def:get_field("Rainbow"):get_data(nil)
};
--
local NormalLvBuffCageData_BuffTypes_type_def = Constants.SDK.find_type_definition("snow.data.NormalLvBuffCageData.BuffTypes");
local BuffTypes = {
    ["Atk"] = NormalLvBuffCageData_BuffTypes_type_def:get_field("Atk"):get_data(nil),
    ["Def"] = NormalLvBuffCageData_BuffTypes_type_def:get_field("Def"):get_data(nil),
    ["Vital"] = NormalLvBuffCageData_BuffTypes_type_def:get_field("Vital"):get_data(nil),
    ["Stamina"] = NormalLvBuffCageData_BuffTypes_type_def:get_field("Stamina"):get_data(nil)
};
--
local hasRainbow = false;
local firstHook = true;
local skipUpdate = false;

local function CreateData()
    local PlayerManager = Constants.SDK.get_managed_singleton("snow.player.PlayerManager");
    if PlayerManager == nil then
        return;
    end

    hasRainbow = getLvBuffCnt_method:call(PlayerManager, LvBuff.Rainbow) > 0;

    local EquipDataManager = Constants.SDK.get_managed_singleton("snow.data.EquipDataManager");
    if EquipDataManager == nil then
        return;
    end
    
    local EquippingLvBuffcageData = getEquippingLvBuffcageData_method:call(EquipDataManager);
    if EquippingLvBuffcageData == nil then
        return;
    end

    this.StatusBuffLimits = {};
    this.BirdsMaxCounts = {};
    this.AcquiredCounts = {};
    this.AcquiredValues = {};

    for k, v in Constants.LUA.pairs(BuffTypes) do
        local StatusBuffLimit = getStatusBuffLimit_method:call(EquippingLvBuffcageData, v);
        local LvBuffNumToMax = calcLvBuffNumToMax_method:call(EquipDataManager, LvBuff[k]);
        this.StatusBuffLimits[k] = StatusBuffLimit;
        this.BirdsMaxCounts[k] = LvBuffNumToMax;
        this.AcquiredCounts[k] = hasRainbow == true and LvBuffNumToMax or Constants.LUA.math_min(Constants.LUA.math_max(getLvBuffCnt_method:call(PlayerManager, LvBuff[k]), 0), LvBuffNumToMax);
        this.AcquiredValues[k] = hasRainbow == true and StatusBuffLimit or Constants.LUA.math_min(Constants.LUA.math_max(calcLvBuffValue_method:call(EquipDataManager, v), 0), StatusBuffLimit);
    end

    this.SpiribirdsHudDataCreated = true;
end

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

local function PostHook_onDestroy()
    Terminate();
    Constants.MasterPlayerIndex = nil;
end

local function getBuffParameters(equipDataManager, playerManager, buffType)
    for k, v in Constants.LUA.pairs(LvBuff) do
        if buffType == v then
            this.AcquiredCounts[k] = Constants.LUA.math_min(Constants.LUA.math_max(getLvBuffCnt_method:call(playerManager, v), 0), this.BirdsMaxCounts[k]);
            this.AcquiredValues[k] = Constants.LUA.math_min(Constants.LUA.math_max(calcLvBuffValue_method:call(equipDataManager, BuffTypes[k]), 0), this.StatusBuffLimits[k]);
            break;
        end
    end
end

local function getCallTimer(playerQuestBase)
    local masterPlayerData = get_PlayerData_method:call(playerQuestBase);
    if masterPlayerData ~= nil then
        local Timer = SpiribirdsCallTimer_field:get_data(masterPlayerData);
        if Timer ~= nil then
            this.SpiribirdsCall_Timer = Constants.LUA.string_format("향응 타이머: %.f초", 60.0 - (Timer / 60.0));
            return;
        end
    end

    this.SpiribirdsCall_Timer = nil;
end

local function onQuestStart()
    if this.SpiribirdsHudDataCreated ~= true then
        return;
    end

    local MapNo = Constants.getQuestMapNo(nil);
    if MapNo == nil then
        return;
    end

    for _, map in Constants.LUA.pairs(Constants.QuestMapList) do
        if map == MapNo then
            for k, v in Constants.LUA.pairs(BuffTypes) do
                addLvBuffCount_method:call(nil, v, this.BirdsMaxCounts[k]);
            end
            break;
        end
    end
end

local function clearLvBuff()
    hasRainbow = false;
    for k in Constants.LUA.pairs(BuffTypes) do
        this.AcquiredCounts[k] = 0;
        this.AcquiredValues[k] = 0;
    end
end

local PlayerQuestBase = nil;
local function PreHook_PlayerQuestBase_start(args)
    PlayerQuestBase = Constants.SDK.to_managed_object(args[2]);
end
local function PostHook_PlayerQuestBase_start()
    if PlayerQuestBase == nil then
        return;
    end

    if isMasterPlayer_method:call(PlayerQuestBase) == true then
        Constants.SDK.hook_vtable(PlayerQuestBase, onDestroy_method, nil, PostHook_onDestroy);
        Constants.GetMasterPlayerId(getPlayerIndex_method:call(PlayerQuestBase));
        CreateData();
    end

    PlayerQuestBase = nil;
end

local subBuffType = nil;
local function PreHook_subLvBuffFromEnemy(args)
    if this.SpiribirdsHudDataCreated ~= true then
        return;
    end

    local playerQuestBase = Constants.SDK.to_managed_object(args[2]);
    if playerQuestBase == nil or isMasterPlayer_method:call(playerQuestBase) ~= true then
        return;
    end

    subBuffType = Constants.SDK.to_int64(args[3]);
end
local function PostHook_subLvBuffFromEnemy(retval)
    if subBuffType ~= nil and Constants.to_bool(retval) == true then
        if subBuffType == LvBuff.Rainbow then
            clearLvBuff();
        else
            local EquipDataManager = Constants.SDK.get_managed_singleton("snow.data.EquipDataManager");
            local PlayerManager = Constants.SDK.get_managed_singleton("snow.player.PlayerManager");
            if EquipDataManager ~= nil and PlayerManager ~= nil then
                getBuffParameters(EquipDataManager, PlayerManager, subBuffType)
            end
        end
    end

    subBuffType = nil;
    return retval;
end

local function PreHook_updateEquipSkill211(args)
    if firstHook == false and skipUpdate == true then
        return;
    end

    local EquipSkill211_PlayerQuestBase = Constants.SDK.to_managed_object(args[2]);
    if EquipSkill211_PlayerQuestBase == nil or isMasterPlayer_method:call(EquipSkill211_PlayerQuestBase) ~= true then
        return;
    end

    if firstHook == true then
        firstHook = false;
        if get_IsInTrainingArea_method:call(EquipSkill211_PlayerQuestBase) == true or IsEnableStage_Skill211_field:get_data(EquipSkill211_PlayerQuestBase) ~= true then
            skipUpdate = true;
            this.SpiribirdsCall_Timer = "향응 비활성 지역";
            return;
        end
    end

    getCallTimer(EquipSkill211_PlayerQuestBase);
end

local PlayerManager_obj = nil;
local addBuffType = nil;
local function PreHook_addLvBuffCnt(args)
    if this.SpiribirdsHudDataCreated ~= true then
        return;
    end

    PlayerManager_obj = Constants.SDK.to_managed_object(args[2]);
    addBuffType = Constants.SDK.to_int64(args[4]);
    if addBuffType == LvBuff.Rainbow then
        hasRainbow = true;
    end

    if hasRainbow == true then
        for k, v in Constants.LUA.pairs(this.StatusBuffLimits) do
            this.AcquiredCounts[k] = this.BirdsMaxCounts[k];
            this.AcquiredValues[k] = v;
        end
    end
end
local function PostHook_addLvBuffCnt()
    if addBuffType == nil then
        PlayerManager_obj = nil;
        return;
    end

    if addBuffType ~= LvBuff.Rainbow then
        if PlayerManager_obj == nil then
            PlayerManager_obj = Constants.SDK.get_managed_singleton("snow.player.PlayerManager");
        end
        local EquipDataManager = Constants.SDK.get_managed_singleton("snow.data.EquipDataManager");
        if PlayerManager_obj ~= nil and EquipDataManager ~= nil then
            getBuffParameters(EquipDataManager, PlayerManager_obj, addBuffType);
        end
    end

    PlayerManager_obj = nil;
    addBuffType = nil;
end

local function PostHook_clearLvBuffCnt()
    if this.SpiribirdsHudDataCreated ~= true then
        return;
    end

    clearLvBuff();
end

local newPlayerIndex = nil;
local function PreHook_changePlayerIndex(args)
    newPlayerIndex = Constants.SDK.to_int64(args[4]);
end
local function PostHook_changePlayerIndex(retval)
    if newPlayerIndex ~= nil then
        local playerBase = Constants.SDK.to_managed_object(retval);
        if playerBase ~= nil and isMasterPlayer_method:call(playerBase) == true then
            Constants.GetMasterPlayerId(newPlayerIndex);
        end
    end

    newPlayerIndex = nil;
    return retval;
end

function this.init()
    Constants.SDK.hook(Constants.type_definitions.WwiseChangeSpaceWatcher_type_def:get_method("onQuestStart"), nil, onQuestStart);
    Constants.SDK.hook(PlayerQuestBase_type_def:get_method("start"), PreHook_PlayerQuestBase_start, PostHook_PlayerQuestBase_start);
    Constants.SDK.hook(PlayerQuestBase_type_def:get_method("subLvBuffFromEnemy(snow.player.PlayerDefine.LvBuff, System.Int32)"), PreHook_subLvBuffFromEnemy, PostHook_subLvBuffFromEnemy);
    Constants.SDK.hook(PlayerQuestBase_type_def:get_method("updateEquipSkill211"), PreHook_updateEquipSkill211);
    Constants.SDK.hook(Constants.type_definitions.PlayerManager_type_def:get_method("addLvBuffCnt(System.Int32, snow.player.PlayerDefine.LvBuff)"), PreHook_addLvBuffCnt, PostHook_addLvBuffCnt);
    Constants.SDK.hook(Constants.type_definitions.PlayerManager_type_def:get_method("clearLvBuffCnt"), nil, PostHook_clearLvBuffCnt);
    Constants.SDK.hook(Constants.type_definitions.PlayerManager_type_def:get_method("changePlayerIndex(snow.player.PlayerIndex, snow.player.PlayerIndex)"), PreHook_changePlayerIndex, PostHook_changePlayerIndex);
end
--
return this;