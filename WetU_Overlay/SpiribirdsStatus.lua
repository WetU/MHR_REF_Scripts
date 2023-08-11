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
local hook_vtable = Constants.sdk.hook_vtable;
local to_int64 = Constants.sdk.to_int64;

local getPlayerData = Constants.getPlayerData;
local getQuestMapNo = Constants.getQuestMapNo;
local QuestMapList = Constants.QuestMapList;
local to_bool = Constants.to_bool;
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
local getMasterPlayer_method = Constants.type_definitions.EnemyUtility_type_def:get_method("getMasterPlayer"); -- static

local PlayerQuestBase_type_def = getMasterPlayer_method:get_return_type();
local onDestroy_method = PlayerQuestBase_type_def:get_method("onDestroy");
local get_IsInTrainingArea_method = PlayerQuestBase_type_def:get_method("get_IsInTrainingArea");
local IsEnableStage_Skill211_field = PlayerQuestBase_type_def:get_field("_IsEnableStage_Skill211");

local isMasterPlayer_method = Constants.type_definitions.PlayerBase_type_def:get_method("isMasterPlayer");

local SpiribirdsCallTimer_field = find_type_definition("snow.player.PlayerData"):get_field("_EquipSkill211_Timer");
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
		Atk = true,
		Def = true,
		Vital = true,
		Stamina = true
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

function this:getBuffParameters(equipDataManager, playerManager, buffType)
	if equipDataManager == nil then
		equipDataManager = self:getEquipDataManager();
	end
	if playerManager == nil then
		playerManager = self:getPlayerManager();
	end

	for k, v in pairs(LvBuff) do
		if buffType == v then
			self.AcquiredCounts[k] = math_min(math_max(getLvBuffCnt_method:call(playerManager, v), 0), self.BirdsMaxCounts[k]);
			self.AcquiredValues[k] = math_min(math_max(calcLvBuffValue_method:call(equipDataManager, BuffTypes[k]), 0), self.StatusBuffLimits[k]);
			break;
		end
	end
end

local function getCallTimer()
	this.SpiribirdsCall_Timer = string_format("향응 타이머: %.f초", 60.0 - (SpiribirdsCallTimer_field:get_data(getPlayerData(getMasterPlayer_method:call(nil))) / 60.0));
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
		if subBuffType == LvBuff.Rainbow then
			hasRainbow = false;

			for _, v in ipairs(this.Buffs) do
				this.AcquiredCounts[v] = 0;
				this.AcquiredValues[v] = 0;
			end
		else
			this:getBuffParameters(nil, nil, subBuffType);
		end
	end

	subBuffType = nil;
	return retval;
end

local function updateEquipSkill211()
	if firstHook == true then
		firstHook = false;
		local MasterPlayerQuestBase = getMasterPlayer_method:call(nil);

		if get_IsInTrainingArea_method:call(MasterPlayerQuestBase) == true or IsEnableStage_Skill211_field:get_data(MasterPlayerQuestBase) ~= true then
			skipUpdate = true;
			this.SpiribirdsCall_Timer = "향응 비활성 지역";
		end

	elseif skipUpdate ~= true then
		getCallTimer();
	end
end

local PreHook_addLvBuffCnt = nil;
local PostHook_addLvBuffCnt = nil;
do
	local addBuffType = nil;
	PreHook_addLvBuffCnt = function(args)
		if this.SpiribirdsHudDataCreated ~= true then
			CreateData();
		end

		local buffType = to_int64(args[4]);

		if buffType == LvBuff.Rainbow then
			hasRainbow = true;
		else
			addBuffType = buffType;
			this.PlayerManager = to_managed_object(args[2]) or get_managed_singleton("snow.player.PlayerManager");
		end
	end
	PostHook_addLvBuffCnt = function()
		if hasRainbow == true then
			for k, v in pairs(this.StatusBuffLimits) do
				this.AcquiredCounts[k] = this.BirdsMaxCounts[k];
				this.AcquiredValues[k] = v;
			end

		elseif addBuffType ~= nil then
			this:getBuffParameters(nil, this.PlayerManager, addBuffType);
		end

		addBuffType = nil;
	end
end

local function init()
	local MasterPlayerQuestBase = getMasterPlayer_method:call(nil);
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
			for k, v in pairs(BuffTypes) do
				addLvBuffCount_method:call(nil, v, this.BirdsMaxCounts[k]);
			end
			break;
		end
	end
end

this.init = init;
this.onQuestStart = onQuestStart;
--
return this;