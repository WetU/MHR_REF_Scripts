local require = require;
local pairs = pairs;

local math = math;
local math_min = math.min;
local math_max = math.max;

local string = string;
local string_format = string.format;

local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
local sdk_to_managed_object = sdk.to_managed_object;
local sdk_to_int64 = sdk.to_int64;
local sdk_hook = sdk.hook;
--
local EquipDataManager_type_def = sdk_find_type_definition("snow.data.EquipDataManager");
local calcLvBuffNumToMax_method = EquipDataManager_type_def:get_method("calcLvBuffNumToMax(snow.player.PlayerDefine.LvBuff)"); -- retval
local calcLvBuffValue_method = EquipDataManager_type_def:get_method("calcLvBuffValue(snow.data.NormalLvBuffCageData.BuffTypes)"); -- retval
local getEquippingLvBuffcageData_method = EquipDataManager_type_def:get_method("getEquippingLvBuffcageData"); -- retval

local getStatusBuffLimit_method = getEquippingLvBuffcageData_method:get_return_type():get_method("getStatusBuffLimit(snow.data.NormalLvBuffCageData.BuffTypes)"); -- retval

local PlayerManager_type_def = sdk_find_type_definition("snow.player.PlayerManager");
local getLvBuffCnt_method = PlayerManager_type_def:get_method("getLvBuffCnt(snow.player.PlayerDefine.LvBuff)"); -- retval

local PlayerQuestBase_type_def = sdk_find_type_definition("snow.player.PlayerQuestBase");
local get_IsInTrainingArea_method = PlayerQuestBase_type_def:get_method("get_IsInTrainingArea"); -- retval
local IsEnableStage_Skill211_field = PlayerQuestBase_type_def:get_field("_IsEnableStage_Skill211");

local PlayerBase_type_def = sdk_find_type_definition("snow.player.PlayerBase");
local isMasterPlayer_method = PlayerBase_type_def:get_method("isMasterPlayer"); -- retval
local getPlayerIndex_method = PlayerBase_type_def:get_method("getPlayerIndex"); -- retval
local get_PlayerData_method = PlayerBase_type_def:get_method("get_PlayerData"); -- retval

local SpiribirdsCallTimer_field = get_PlayerData_method:get_return_type():get_field("_EquipSkill211_Timer");

local LvBuff_type_def = sdk_find_type_definition("snow.player.PlayerDefine.LvBuff");
local LvBuff = {
    ["Atk"] = LvBuff_type_def:get_field("Attack"):get_data(nil),
    ["Def"] = LvBuff_type_def:get_field("Defence"):get_data(nil),
    ["Vital"] = LvBuff_type_def:get_field("Vital"):get_data(nil),
    ["Stamina"] = LvBuff_type_def:get_field("Stamina"):get_data(nil),
    ["Rainbow"] = LvBuff_type_def:get_field("Rainbow"):get_data(nil)
};

local NormalLvBuffCageData_BuffTypes_type_def = sdk_find_type_definition("snow.data.NormalLvBuffCageData.BuffTypes");
local BuffTypes = {
    ["Atk"] = NormalLvBuffCageData_BuffTypes_type_def:get_field("Atk"):get_data(nil),
    ["Def"] = NormalLvBuffCageData_BuffTypes_type_def:get_field("Def"):get_data(nil),
    ["Vital"] = NormalLvBuffCageData_BuffTypes_type_def:get_field("Vital"):get_data(nil),
    ["Stamina"] = NormalLvBuffCageData_BuffTypes_type_def:get_field("Stamina"):get_data(nil)
};
--
local Constants = require("WetU_Overlay.Constants");
local HarvestMoonTimer = require("WetU_Overlay.HarvestMoonTimer");
--
local this = {
    SpiribirdsHudDataCreated = false,
    SpiribirdsCall_Timer = nil,
    StatusBuffLimits = nil,
    AcquiredValues = nil,
    BirdsMaxCounts = nil,
    AcquiredCounts = nil,
};
--
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
    hasRainbow = false;
    firstHook = true;
    skipUpdate = false;
end

local function getCountsAndValues(playerManager, equipDataManager, buffType)
    for k, v in pairs(LvBuff) do
        if buffType == v then
            this.AcquiredCounts[k] = math_min(math_max(getLvBuffCnt_method:call(playerManager, v), 0), this.BirdsMaxCounts[k]);
            this.AcquiredValues[k] = math_min(math_max(calcLvBuffValue_method:call(equipDataManager, BuffTypes[k]), 0), this.StatusBuffLimits[k]);
            break;
        end
    end
end

local function getCallTimer(playerQuestBase)
    local masterPlayerData = get_PlayerData_method:call(playerQuestBase);
    if masterPlayerData then
        local Timer = SpiribirdsCallTimer_field:get_data(masterPlayerData);
        this.SpiribirdsCall_Timer = Timer ~= nil and string_format(TimerString.Enabled, 60.0 - (Timer / 60.0)) or nil;
    end
end

local PlayerQuestBase_start = nil;
sdk_hook(PlayerQuestBase_type_def:get_method("start"), function(args)
    PlayerQuestBase_start = sdk_to_managed_object(args[2]);
end, function()
    if PlayerQuestBase_start and isMasterPlayer_method:call(PlayerQuestBase_start) then
        Constants.MasterPlayerIndex = getPlayerIndex_method:call(PlayerQuestBase_start);
        local EquipDataManager = sdk_get_managed_singleton("snow.data.EquipDataManager");
        local PlayerManager = sdk_get_managed_singleton("snow.player.PlayerManager");
        if EquipDataManager and PlayerManager then
            hasRainbow = getLvBuffCnt_method:call(PlayerManager, LvBuff.Rainbow) > 0;
            local EquippingLvBuffcageData = getEquippingLvBuffcageData_method:call(EquipDataManager);
            if EquippingLvBuffcageData then
                this.StatusBuffLimits = {};
                this.BirdsMaxCounts = {};
                this.AcquiredCounts = {};
                this.AcquiredValues = {};
                for k, v in pairs(LvBuff) do
                    if k ~= "Rainbow" then
                        local StatusBuffLimit = getStatusBuffLimit_method:call(EquippingLvBuffcageData, BuffTypes[k]);
                        local LvBuffNumToMax = calcLvBuffNumToMax_method:call(EquipDataManager, v);

                        this.StatusBuffLimits[k] = StatusBuffLimit;
                        this.BirdsMaxCounts[k] = LvBuffNumToMax;
                        this.AcquiredCounts[k] = hasRainbow and LvBuffNumToMax or math_min(math_max(getLvBuffCnt_method:call(PlayerManager, v), 0), LvBuffNumToMax);
                        this.AcquiredValues[k] = hasRainbow and StatusBuffLimit or math_min(math_max(calcLvBuffValue_method:call(EquipDataManager, BuffTypes[k]), 0), StatusBuffLimit);
                    end
                end
                this.SpiribirdsHudDataCreated = true;
            end
        end
    end
    PlayerQuestBase_start = nil;
end);

local PlayerQuestBase_subLvBuffFromEnemy = nil;
local subBuffType = nil;
sdk_hook(PlayerQuestBase_type_def:get_method("subLvBuffFromEnemy(snow.player.PlayerDefine.LvBuff, System.Int32)"), function(args)
    if this.SpiribirdsHudDataCreated then
        PlayerQuestBase_subLvBuffFromEnemy = sdk_to_managed_object(args[2]);
        subBuffType = sdk_to_int64(args[3]) & 0xFFFFFFFF;
    end
end, function(retval)
    if PlayerQuestBase_subLvBuffFromEnemy and isMasterPlayer_method:call(PlayerQuestBase_subLvBuffFromEnemy) and (sdk_to_int64(retval) & 1) == 1 and subBuffType ~= nil then
        if subBuffType == LvBuff.Rainbow then
            hasRainbow = false;
            for k, v in pairs(LvBuff) do
                this.AcquiredCounts[k] = 0;
                this.AcquiredValues[k] = 0;
            end
        else
            local EquipDataManager = sdk_get_managed_singleton("snow.data.EquipDataManager");
            local PlayerManager = sdk_get_managed_singleton("snow.player.PlayerManager");
            if EquipDataManager and PlayerManager then
                getCountsAndValues(PlayerManager, EquipDataManager, subBuffType);
            end
        end
    end
    PlayerQuestBase_subLvBuffFromEnemy = nil;
    subBuffType = nil;
    return retval;
end);

local addBuffType = nil;
local PlayerManager_obj = nil;
sdk_hook(PlayerManager_type_def:get_method("addLvBuffCnt(System.Int32, snow.player.PlayerDefine.LvBuff)"), function(args)
    if this.SpiribirdsHudDataCreated then
        addBuffType = sdk_to_int64(args[4]) & 0xFFFFFFFF;
        if addBuffType ~= nil and addBuffType ~= LvBuff.Rainbow then
            PlayerManager_obj = sdk_to_managed_object(args[2]);
        end
    end
end, function()
    if addBuffType == LvBuff.Rainbow then
        hasRainbow = true;
    end

    if hasRainbow then
        for k, v in pairs(this.StatusBuffLimits) do
            this.AcquiredCounts[k] = this.BirdsMaxCounts[k];
            this.AcquiredValues[k] = v;
        end
    else
        if PlayerManager_obj then
            local EquipDataManager = sdk_get_managed_singleton("snow.data.EquipDataManager");
            if EquipDataManager then
                getCountsAndValues(PlayerManager_obj, EquipDataManager, addBuffType);
            end
        end
    end
    addBuffType = nil;
    PlayerManager_obj = nil;
end);

sdk_hook(PlayerManager_type_def:get_method("clearLvBuffCnt"), nil, function()
    if this.SpiribirdsHudDataCreated then
        hasRainbow = false;
        this.AcquiredValues = nil;
        this.AcquiredCounts = nil;
    end
end);

local PlayerQuestBase_obj = nil;
sdk_hook(PlayerQuestBase_type_def:get_method("updateEquipSkill211"), function(args)
    if firstHook or not skipUpdate then
        PlayerQuestBase_obj = sdk_to_managed_object(args[2]);
    end
end, function()
    if PlayerQuestBase_obj and isMasterPlayer_method:call(PlayerQuestBase_obj) then
        if firstHook then
            firstHook = false;
            if get_IsInTrainingArea_method:call(PlayerQuestBase_obj) or not IsEnableStage_Skill211_field:get_data(PlayerQuestBase_obj) then
                skipUpdate = true;
                this.SpiribirdsCall_Timer = TimerString.Disabled;
            else
                getCallTimer(PlayerQuestBase_obj);
            end
        else
            getCallTimer(PlayerQuestBase_obj);
        end
    end
    PlayerQuestBase_obj = nil;
end);

local newPlayerIndex = nil;
sdk_hook(PlayerManager_type_def:get_method("changePlayerIndex(snow.player.PlayerIndex, snow.player.PlayerIndex)"), function(args)
    newPlayerIndex = sdk_to_int64(args[4]) & 0xFF;
end, function(retval)
    if newPlayerIndex ~= nil then
        local playerBase = sdk_to_managed_object(retval);
        if playerBase and isMasterPlayer_method:call(playerBase) then
            Constants.MasterPlayerIndex = newPlayerIndex;
        end
    end
    newPlayerIndex = nil;
end);

local newMasterPlayerIndex = nil;
sdk_hook(PlayerManager_type_def:get_method("changeMasterPlayerID(snow.player.PlayerIndex)"), function(args)
    newMasterPlayerIndex = sdk_to_int64(args[3]) & 0xFF;
end, function()
    if newMasterPlayerIndex ~= nil then
        Constants.MasterPlayerIndex = newMasterPlayerIndex;
    end
    newMasterPlayerIndex = nil;
end);

sdk_hook(PlayerQuestBase_type_def:get_method("onDestroy"), nil, function()
    TerminateSpiribirdsHud();
    Constants.MasterPlayerIndex = nil;
    HarvestMoonTimer.HarvestMoonTimer_Inside = nil;
    HarvestMoonTimer.HarvestMoonTimer_Outside = nil;
end);

return this;