local Constants = _G.require("Constants.Constants");

local pairs = Constants.lua.pairs;

local math_min = Constants.lua.math_min;
local math_max = Constants.lua.math_max;

local string_format = Constants.lua.string_format;

local find_type_definition = Constants.sdk.find_type_definition;
local get_managed_singleton = Constants.sdk.get_managed_singleton;
local to_managed_object = Constants.sdk.to_managed_object;
local hook = Constants.sdk.hook;
local hook_vtable = Constants.sdk.hook_vtable;
local to_int64 = Constants.sdk.to_int64;

local getMasterPlayerBase = Constants.getMasterPlayerBase;
local getQuestMapNo = Constants.getQuestMapNo;
local QuestMapList = Constants.QuestMapList;
local to_bool = Constants.to_bool;
local getTableIndex = Constants.getTableIndex;
--
local this = {
	PlayerManager = nil,
	EquipDataManager = nil,

	init = true,
	onQuestStart = true,

	SpiribirdsHudDataCreated = nil,
	SpiribirdsCall_Timer = nil,

	StatusBuffLimits = nil,
	AcquiredValues = nil,
	BirdsMaxCounts = nil,
	AcquiredCounts = nil
};
--
local EquipDataManager_type_def = Constants.type_definitions.EquipDataManager_type_def;
local calcLvBuffNumToMax_method = EquipDataManager_type_def:get_method("calcLvBuffNumToMax(snow.player.PlayerDefine.LvBuff)");
local addLvBuffCount_method = EquipDataManager_type_def:get_method("addLvBuffCount(snow.data.NormalLvBuffCageData.BuffTypes, System.Int32)"); -- static
local calcLvBuffValue_method = EquipDataManager_type_def:get_method("calcLvBuffValue(snow.data.NormalLvBuffCageData.BuffTypes)");
local getEquippingLvBuffcageData_method = EquipDataManager_type_def:get_method("getEquippingLvBuffcageData");

local getStatusBuffLimit_method = getEquippingLvBuffcageData_method:get_return_type():get_method("getStatusBuffLimit(snow.data.NormalLvBuffCageData.BuffTypes)");
--
local PlayerManager_type_def = find_type_definition("snow.player.PlayerManager");
local getLvBuffCnt_method = PlayerManager_type_def:get_method("getLvBuffCnt(snow.player.PlayerDefine.LvBuff)");
--
local getMasterPlayerQuestBase_method = Constants.type_definitions.EnemyUtility_type_def:get_method("getMasterPlayer"); -- static

local PlayerQuestBase_type_def = getMasterPlayerQuestBase_method:get_return_type();
local onDestroy_method = PlayerQuestBase_type_def:get_method("onDestroy");
local get_IsInTrainingArea_method = PlayerQuestBase_type_def:get_method("get_IsInTrainingArea");
local IsEnableStage_Skill211_field = PlayerQuestBase_type_def:get_field("_IsEnableStage_Skill211");

local PlayerBase_type_def = Constants.type_definitions.PlayerBase_type_def;
local isMasterPlayer_method = PlayerBase_type_def:get_method("isMasterPlayer");
local get_PlayerData_method = PlayerBase_type_def:get_method("get_PlayerData");

local SpiribirdsCallTimer_field = find_type_definition("snow.player.PlayerData"):get_field("_EquipSkill211_Timer");
--
local LvBuff = {
	0, -- Atk
	1, -- Def
	2, -- Vital
	3, -- Stamina
	4  -- Rainbow
};
local BuffTypes = {
	2, -- Atk
	3, -- Def
	0, -- Vital
	1  -- Stamina
};
--
local hasRainbow = false;
local firstHook = true;
local skipUpdate = false;

function this:getPlayerManager()
	if self.PlayerManager == nil then
		self.PlayerManager = get_managed_singleton("snow.player.PlayerManager");
	end

	return self.PlayerManager;
end

function this:getEquipDataManager()
	if self.EquipDataManager == nil then
		self.EquipDataManager = get_managed_singleton("snow.data.EquipDataManager");
	end

	return self.EquipDataManager;
end

local function mkTable()
	local table = {
		true,
		true,
		true,
		true
	};

	return table;
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

local function CreateData()
	local PlayerManager = this:getPlayerManager();
	local EquipDataManager = this:getEquipDataManager();

	hasRainbow = getLvBuffCnt_method:call(PlayerManager, LvBuff.Rainbow) > 0;
	local EquippingLvBuffcageData = getEquippingLvBuffcageData_method:call(EquipDataManager);

	this.StatusBuffLimits = mkTable();
	this.BirdsMaxCounts = mkTable();
	this.AcquiredCounts = mkTable();
	this.AcquiredValues = mkTable();

	for i = 1, 4, 1 do
		local BuffType = BuffTypes[i];
		local LvBuffType = LvBuff[i];
		local StatusBuffLimit = getStatusBuffLimit_method:call(EquippingLvBuffcageData, BuffType);
		local LvBuffNumToMax = calcLvBuffNumToMax_method:call(EquipDataManager, LvBuffType);
		this.StatusBuffLimits[i] = StatusBuffLimit;
		this.BirdsMaxCounts[i] = LvBuffNumToMax;
		this.AcquiredValues[i] = hasRainbow == true and StatusBuffLimit or math_min(math_max(calcLvBuffValue_method:call(EquipDataManager, BuffType), 0), StatusBuffLimit);
		this.AcquiredCounts[i] = hasRainbow == true and LvBuffNumToMax or math_min(math_max(getLvBuffCnt_method:call(PlayerManager, LvBuffType), 0), LvBuffNumToMax);
	end

	this.SpiribirdsHudDataCreated = true;
end

function this:getBuffParameters(equipDataManager, playerManager, buffType)
	if equipDataManager == nil then
		equipDataManager = self:getEquipDataManager();
	end
	if playerManager == nil then
		playerManager = self:getPlayerManager();
	end

	for i = 1, 4, 1 do
		local LvBuffType = LvBuff[i];
		if buffType == LvBuffType then
			self.AcquiredCounts[i] = math_min(math_max(getLvBuffCnt_method:call(playerManager, LvBuffType), 0), self.BirdsMaxCounts[i]);
			self.AcquiredValues[i] = math_min(math_max(calcLvBuffValue_method:call(equipDataManager, BuffTypes[i]), 0), self.StatusBuffLimits[i]);
			break;
		end
	end
end

local function getCallTimer()
	this.SpiribirdsCall_Timer = string_format("향응 타이머: %.f초", 60.0 - (SpiribirdsCallTimer_field:get_data(get_PlayerData_method:call(getMasterPlayerBase())) / 60.0));
end

local function init_Data(playerQuestBase)
	CreateData();
	hook_vtable(playerQuestBase, onDestroy_method, nil, Terminate);
end

local PreHook_PlayerQuestBase_start = nil;
local PostHook_PlayerQuestBase_start = nil;
do
	local PlayerQuestBase = nil;
	PreHook_PlayerQuestBase_start = function(args)
		PlayerQuestBase = to_managed_object(args[2]);
	end
	PostHook_PlayerQuestBase_start = function()
		if isMasterPlayer_method:call(PlayerQuestBase) == true then
			init_Data(PlayerQuestBase);
		end

		PlayerQuestBase = nil;
	end
end

local subBuffType = nil;
local function PreHook_subLvBuffFromEnemy(args)
	if isMasterPlayer_method:call(to_managed_object(args[2])) == true then
		if this.SpiribirdsHudDataCreated ~= true then
			CreateData();
		end

		subBuffType = to_int64(args[3]);
	end
end
local function PostHook_subLvBuffFromEnemy(retval)
	if subBuffType ~= nil and to_bool(retval) == true then
		if subBuffType == LvBuff[5] then
			hasRainbow = false;

			for i = 1, 4, 1 do
				this.AcquiredCounts[i] = 0;
				this.AcquiredValues[i] = 0;
			end
		else
			this:getBuffParameters(nil, nil, subBuffType);
		end
	end

	subBuffType = nil;
	return retval;
end

local addBuffType = nil;
local function PreHook_addLvBuffCnt(args)
	if this.SpiribirdsHudDataCreated ~= true then
		CreateData();
	end

	local buffType = to_int64(args[4]);

	if buffType == LvBuff[5] then
		hasRainbow = true;
	else
		addBuffType = buffType;
		this.PlayerManager = to_managed_object(args[2]) or get_managed_singleton("snow.player.PlayerManager");
	end
end
local function PostHook_addLvBuffCnt()
	if hasRainbow == true then
		for i = 1, 4, 1 do
			this.AcquiredCounts[i] = this.BirdsMaxCounts[i];
			this.AcquiredValues[i] = this.StatusBuffLimits[i];
		end

	elseif addBuffType ~= nil then
		this:getBuffParameters(nil, this.PlayerManager, addBuffType);
	end

	addBuffType = nil;
end

local function updateEquipSkill211()
	if firstHook == true then
		firstHook = false;
		local MasterPlayerQuestBase = getMasterPlayerQuestBase_method:call(nil);

		if get_IsInTrainingArea_method:call(MasterPlayerQuestBase) == true or IsEnableStage_Skill211_field:get_data(MasterPlayerQuestBase) ~= true then
			skipUpdate = true;
			this.SpiribirdsCall_Timer = "향응 비활성 지역";
		end

	elseif skipUpdate ~= true then
		getCallTimer();
	end
end

local function init()
	local MasterPlayerQuestBase = getMasterPlayerQuestBase_method:call(nil);
	if MasterPlayerQuestBase ~= nil then
		init_Data(MasterPlayerQuestBase);
	end

	hook(PlayerQuestBase_type_def:get_method("start"), PreHook_PlayerQuestBase_start, PostHook_PlayerQuestBase_start);
	hook(PlayerQuestBase_type_def:get_method("subLvBuffFromEnemy(snow.player.PlayerDefine.LvBuff, System.Int32)"), PreHook_subLvBuffFromEnemy, PostHook_subLvBuffFromEnemy);
	hook(PlayerQuestBase_type_def:get_method("updateEquipSkill211"), nil, updateEquipSkill211);
	hook(PlayerManager_type_def:get_method("addLvBuffCnt(System.Int32, snow.player.PlayerDefine.LvBuff)"), PreHook_addLvBuffCnt, PostHook_addLvBuffCnt);
end

local function onQuestStart()
	if this.SpiribirdsHudDataCreated ~= true then
		CreateData();
	end

	local MapNo = getQuestMapNo(nil);

	for _, map in pairs(QuestMapList) do
		if map == MapNo then
			for i = 1, 4, 1 do
				addLvBuffCount_method:call(nil, BuffTypes[i], this.BirdsMaxCounts[i]);
			end
			break;
		end
	end
end

this.init = init;
this.onQuestStart = onQuestStart;
--
return this;