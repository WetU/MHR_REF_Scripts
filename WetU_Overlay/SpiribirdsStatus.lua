local require = require;
local Constants = require("Constants.Constants");
if not Constants then
	return;
end

local HarvestMoonTimer = require("WetU_Overlay.HarvestMoonTimer");
--
local this = {
    SpiribirdsHudDataCreated = false,
    SpiribirdsCall_Timer = nil,
    StatusBuffLimits = nil,
    AcquiredValues = nil,
    BirdsMaxCounts = nil,
    AcquiredCounts = nil
};
--
local calcLvBuffNumToMax_method = Constants.type_definitions.EquipDataManager_type_def:get_method("calcLvBuffNumToMax(snow.player.PlayerDefine.LvBuff)"); -- retval
local calcLvBuffValue_method = Constants.type_definitions.EquipDataManager_type_def:get_method("calcLvBuffValue(snow.data.NormalLvBuffCageData.BuffTypes)"); -- retval
local getEquippingLvBuffcageData_method = Constants.type_definitions.EquipDataManager_type_def:get_method("getEquippingLvBuffcageData"); -- retval

local getStatusBuffLimit_method = getEquippingLvBuffcageData_method:get_return_type():get_method("getStatusBuffLimit(snow.data.NormalLvBuffCageData.BuffTypes)"); -- retval

local getLvBuffCnt_method = Constants.type_definitions.PlayerManager_type_def:get_method("getLvBuffCnt(snow.player.PlayerDefine.LvBuff)"); -- retval

local onDestroy_method = Constants.type_definitions.PlayerQuestBase_type_def:get_method("onDestroy");
local get_IsInTrainingArea_method = Constants.type_definitions.PlayerQuestBase_type_def:get_method("get_IsInTrainingArea"); -- retval
local IsEnableStage_Skill211_field = Constants.type_definitions.PlayerQuestBase_type_def:get_field("_IsEnableStage_Skill211");

local PlayerBase_type_def = Constants.SDK.find_type_definition("snow.player.PlayerBase");
local isMasterPlayer_method = PlayerBase_type_def:get_method("isMasterPlayer"); -- retval
local getPlayerIndex_method = PlayerBase_type_def:get_method("getPlayerIndex"); -- retval
local get_PlayerData_method = PlayerBase_type_def:get_method("get_PlayerData"); -- retval

local SpiribirdsCallTimer_field = get_PlayerData_method:get_return_type():get_field("_EquipSkill211_Timer");

local LvBuff_type_def = Constants.SDK.find_type_definition("snow.player.PlayerDefine.LvBuff");
local LvBuff = {
    ["Atk"] = LvBuff_type_def:get_field("Attack"):get_data(nil),
    ["Def"] = LvBuff_type_def:get_field("Defence"):get_data(nil),
    ["Vital"] = LvBuff_type_def:get_field("Vital"):get_data(nil),
    ["Stamina"] = LvBuff_type_def:get_field("Stamina"):get_data(nil),
    ["Rainbow"] = LvBuff_type_def:get_field("Rainbow"):get_data(nil)
};

local NormalLvBuffCageData_BuffTypes_type_def = Constants.SDK.find_type_definition("snow.data.NormalLvBuffCageData.BuffTypes");
local BuffTypes = {
    ["Atk"] = NormalLvBuffCageData_BuffTypes_type_def:get_field("Atk"):get_data(nil),
    ["Def"] = NormalLvBuffCageData_BuffTypes_type_def:get_field("Def"):get_data(nil),
    ["Vital"] = NormalLvBuffCageData_BuffTypes_type_def:get_field("Vital"):get_data(nil),
    ["Stamina"] = NormalLvBuffCageData_BuffTypes_type_def:get_field("Stamina"):get_data(nil)
};
--
local PlayerQuestBase = nil;

local TimerString = {
    Disabled = "향응 비활성 지역",
    Enabled = "향응 타이머: %.f초"
};

local hasRainbow = false;
local firstHook = true;
local skipUpdate = false;

local function TerminateSpiribirdsHud()
    this.SpiribirdsHudDataCreated = false;
    this.SpiribirdsCall_Timer = nil;
    this.StatusBuffLimits = nil;
    this.AcquiredValues = nil;
    this.BirdsMaxCounts = nil;
    this.AcquiredCounts = nil;
    PlayerQuestBase = nil;
    hasRainbow = false;
    firstHook = true;
    skipUpdate = false;
end

local function getCountsAndValues(playerManager, equipDataManager, buffType)
    for k, v in Constants.LUA.pairs(LvBuff) do
        if buffType == v then
            this.AcquiredCounts[k] = Constants.LUA.math_min(Constants.LUA.math_max(getLvBuffCnt_method:call(playerManager, v), 0), this.BirdsMaxCounts[k]);
            this.AcquiredValues[k] = Constants.LUA.math_min(Constants.LUA.math_max(calcLvBuffValue_method:call(equipDataManager, BuffTypes[k]), 0), this.StatusBuffLimits[k]);
            break;
        end
    end
end

local function getCallTimer()
    local masterPlayerData = get_PlayerData_method:call(PlayerQuestBase);
    if masterPlayerData then
        local Timer = SpiribirdsCallTimer_field:get_data(masterPlayerData);
        this.SpiribirdsCall_Timer = Timer ~= nil and Constants.LUA.string_format(TimerString.Enabled, 60.0 - (Timer / 60.0)) or nil;
    end
end

Constants.SDK.hook(Constants.type_definitions.PlayerQuestBase_type_def:get_method("start"), function(args)
    PlayerQuestBase = Constants.SDK.to_managed_object(args[2]);
end, function()
    if PlayerQuestBase and isMasterPlayer_method:call(PlayerQuestBase) then
        Constants.GetMasterPlayerId(getPlayerIndex_method:call(PlayerQuestBase));
        local EquipDataManager = Constants.SDK.get_managed_singleton("snow.data.EquipDataManager");
        local PlayerManager = Constants.SDK.get_managed_singleton("snow.player.PlayerManager");
        if EquipDataManager and PlayerManager then
            hasRainbow = getLvBuffCnt_method:call(PlayerManager, LvBuff.Rainbow) > 0;
            local EquippingLvBuffcageData = getEquippingLvBuffcageData_method:call(EquipDataManager);
            if EquippingLvBuffcageData then
                this.StatusBuffLimits = {};
                this.BirdsMaxCounts = {};
                this.AcquiredCounts = {};
                this.AcquiredValues = {};
                for k, v in Constants.LUA.pairs(LvBuff) do
                    if k ~= "Rainbow" then
                        local StatusBuffLimit = getStatusBuffLimit_method:call(EquippingLvBuffcageData, BuffTypes[k]);
                        local LvBuffNumToMax = calcLvBuffNumToMax_method:call(EquipDataManager, v);
                        this.StatusBuffLimits[k] = StatusBuffLimit;
                        this.BirdsMaxCounts[k] = LvBuffNumToMax;
                        this.AcquiredCounts[k] = hasRainbow and LvBuffNumToMax or Constants.LUA.math_min(Constants.LUA.math_max(getLvBuffCnt_method:call(PlayerManager, v), 0), LvBuffNumToMax);
                        this.AcquiredValues[k] = hasRainbow and StatusBuffLimit or Constants.LUA.math_min(Constants.LUA.math_max(calcLvBuffValue_method:call(EquipDataManager, BuffTypes[k]), 0), StatusBuffLimit);
                    end
                end
                this.SpiribirdsHudDataCreated = true;
            end
        end
        Constants.SDK.hook_vtable(PlayerQuestBase, onDestroy_method, nil, function()
            TerminateSpiribirdsHud();
            HarvestMoonTimer.TerminateHarvestMoon();
            Constants.MasterPlayerIndex = nil;
        end);
    else
        PlayerQuestBase = nil;
    end
end);

local subBuffType = nil;
Constants.SDK.hook(Constants.type_definitions.PlayerQuestBase_type_def:get_method("subLvBuffFromEnemy(snow.player.PlayerDefine.LvBuff, System.Int32)"), function(args)
    if this.SpiribirdsHudDataCreated and PlayerQuestBase and (PlayerQuestBase == Constants.SDK.to_managed_object(args[2])) then
        subBuffType = Constants.SDK.to_int64(args[3]) & 0xFFFFFFFF;
    end
end, function(retval)
    if subBuffType ~= nil and (Constants.SDK.to_int64(retval) & 1) == 1 then
        if subBuffType == LvBuff.Rainbow then
            hasRainbow = false;
            for k, v in Constants.LUA.pairs(LvBuff) do
                this.AcquiredCounts[k] = 0;
                this.AcquiredValues[k] = 0;
            end
        else
            local EquipDataManager = Constants.SDK.get_managed_singleton("snow.data.EquipDataManager");
            local PlayerManager = Constants.SDK.get_managed_singleton("snow.player.PlayerManager");
            if EquipDataManager and PlayerManager then
                getCountsAndValues(PlayerManager, EquipDataManager, subBuffType);
            end
        end
    end
    subBuffType = nil;
    return retval;
end);

local doUpdate = nil;
Constants.SDK.hook(Constants.type_definitions.PlayerQuestBase_type_def:get_method("updateEquipSkill211"), function(args)
    if PlayerQuestBase and (PlayerQuestBase == Constants.SDK.to_managed_object(args[2])) and (firstHook or not skipUpdate) then
        doUpdate = true;
    end
end, function()
    if doUpdate then
        if firstHook then
            firstHook = false;
            if get_IsInTrainingArea_method:call(PlayerQuestBase) or not IsEnableStage_Skill211_field:get_data(PlayerQuestBase) then
                skipUpdate = true;
                this.SpiribirdsCall_Timer = TimerString.Disabled;
            else
                getCallTimer();
            end
        else
            getCallTimer();
        end
    end
    doUpdate = nil;
end);

local addBuffType = nil;
local PlayerManager_obj = nil;
Constants.SDK.hook(Constants.type_definitions.PlayerManager_type_def:get_method("addLvBuffCnt(System.Int32, snow.player.PlayerDefine.LvBuff)"), function(args)
    if this.SpiribirdsHudDataCreated then
        addBuffType = Constants.SDK.to_int64(args[4]) & 0xFFFFFFFF;
        if addBuffType ~= nil and addBuffType ~= LvBuff.Rainbow then
            PlayerManager_obj = Constants.SDK.to_managed_object(args[2]);
        end
    end
end, function()
    if addBuffType == LvBuff.Rainbow then
        hasRainbow = true;
    end

    if hasRainbow then
        for k, v in Constants.LUA.pairs(this.StatusBuffLimits) do
            this.AcquiredCounts[k] = this.BirdsMaxCounts[k];
            this.AcquiredValues[k] = v;
        end
    else
        if PlayerManager_obj then
            local EquipDataManager = Constants.SDK.get_managed_singleton("snow.data.EquipDataManager");
            if EquipDataManager then
                getCountsAndValues(PlayerManager_obj, EquipDataManager, addBuffType);
            end
        end
    end
    addBuffType = nil;
    PlayerManager_obj = nil;
end);

Constants.SDK.hook(Constants.type_definitions.PlayerManager_type_def:get_method("clearLvBuffCnt"), nil, function()
    if this.SpiribirdsHudDataCreated then
        hasRainbow = false;
        this.AcquiredValues = 0;
        this.AcquiredCounts = 0;
    end
end);

local newPlayerIndex = nil;
Constants.SDK.hook(Constants.type_definitions.PlayerManager_type_def:get_method("changePlayerIndex(snow.player.PlayerIndex, snow.player.PlayerIndex)"), function(args)
    newPlayerIndex = Constants.SDK.to_int64(args[4]) & 0xFF;
end, function(retval)
    if newPlayerIndex ~= nil then
        local playerBase = Constants.SDK.to_managed_object(retval);
        if playerBase and isMasterPlayer_method:call(playerBase) then
            Constants.GetMasterPlayerId(newPlayerIndex);
        end
    end
    newPlayerIndex = nil;
    return retval;
end);

Constants.SDK.hook(Constants.type_definitions.PlayerManager_type_def:get_method("changeMasterPlayerID(snow.player.PlayerIndex)"), function(args)
    Constants.GetMasterPlayerId(Constants.SDK.to_int64(args[3]) & 0xFF);
end);

return this;