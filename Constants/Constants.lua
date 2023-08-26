local _G = _G;
--
local math = _G.math;
local sdk = _G.sdk;
local imgui = _G.imgui;
--
local hook = sdk.hook;
local hook_vtable = sdk.hook_vtable;
local find_type_definition = sdk.find_type_definition;
local get_managed_singleton = sdk.get_managed_singleton;
local to_managed_object = sdk.to_managed_object;
local to_ptr = sdk.to_ptr;
local to_int64 = sdk.to_int64;
local SKIP_ORIGINAL = sdk.PreHookResult.SKIP_ORIGINAL;
--
local QuestManager_type_def = find_type_definition("snow.QuestManager");
local VillageAreaManager_type_def = find_type_definition("snow.VillageAreaManager");
local DataShortcut_type_def = find_type_definition("snow.data.DataShortcut");
local FacilityDataManager_type_def = find_type_definition("snow.data.FacilityDataManager");
local ChatManager_type_def = find_type_definition("snow.gui.ChatManager");
local GuiManager_type_def = find_type_definition("snow.gui.GuiManager");
local PlayerLobbyBase_type_def = find_type_definition("snow.player.PlayerLobbyBase");
--
local TRUE_POINTER = to_ptr(true);
--
local get_Kitchen_method = FacilityDataManager_type_def:get_method("get_Kitchen");
local KitchenFacility_type_def = get_Kitchen_method:get_return_type();
local get_BbqFunc_method = KitchenFacility_type_def:get_method("get_BbqFunc");
local BbqFunc_type_def = get_BbqFunc_method:get_return_type();
local outputTicket_method = BbqFunc_type_def:get_method("outputTicket");
--
local getTrg_method = find_type_definition("snow.GameKeyboard.HardwareKeyboard"):get_method("getTrg(via.hid.KeyboardKey)"); -- static
--
local get_CurrentStatus_method = find_type_definition("snow.SnowGameManager"):get_method("get_CurrentStatus");
--
local set_FadeMode_method = find_type_definition("snow.FadeManager"):get_method("set_FadeMode(snow.FadeManager.MODE)");
--
local getMapNo_method = QuestManager_type_def:get_method("getMapNo");
--
local getQuestLife_method = QuestManager_type_def:get_method("getQuestLife");
local getDeathNum_method = QuestManager_type_def:get_method("getDeathNum");
--
local reqAddChatInfomation_method = ChatManager_type_def:get_method("reqAddChatInfomation(System.String, System.UInt32)");
--
local VillagePoint_type_def = find_type_definition("snow.data.VillagePoint");
local get_Point_method = VillagePoint_type_def:get_method("get_Point"); -- static
local subPoint_method = VillagePoint_type_def:get_method("subPoint(System.UInt32)"); -- static
--
local getCountOfAll_method = find_type_definition("snow.data.ContentsIdDataManager"):get_method("getCountOfAll(snow.data.ContentsIdSystem.ItemId)");
--
local closeRewardDialog_method = GuiManager_type_def:get_method("closeRewardDialog");
--
local this = {
	["lua"] = {
		["pairs"] = _G.pairs,
		["tostring"] = _G.tostring,
		["math_min"] = math.min,
		["math_max"] = math.max,
		["string_format"] = _G.string.format
	},
	["sdk"] = {
		["create_managed_array"] = sdk.create_managed_array,
		["hook"] = hook,
		["hook_vtable"] = hook_vtable,
		["find_type_definition"] = find_type_definition,
		["get_managed_singleton"] = get_managed_singleton,
		["to_managed_object"] = to_managed_object,
		["to_ptr"] = to_ptr,
		["to_int64"] = to_int64,
		["to_float"] = sdk.to_float,
		["to_valuetype"] = sdk.to_valuetype,
		["SKIP_ORIGINAL"] = SKIP_ORIGINAL,
		["CALL_ORIGINAL"] = sdk.PreHookResult.CALL_ORIGINAL
	},
	["imgui"] = {
		["push_font"] = imgui.push_font,
		["begin_window"] = imgui.begin_window,
		["end_window"] = imgui.end_window,
		["begin_table"] = imgui.begin_table,
		["table_setup_column"] = imgui.table_setup_column,
		["table_next_column"] = imgui.table_next_column,
		["table_headers_row"] = imgui.table_headers_row,
		["table_next_row"] = imgui.table_next_row,
		["end_table"] = imgui.end_table,
		["text"] = imgui.text,
		["text_colored"] = imgui.text_colored,
		["spacing"] = imgui.spacing
	},
	["type_definitions"] = {
		["Application_type_def"] = find_type_definition("via.Application"),
		["QuestManager_type_def"] = QuestManager_type_def,
		["VillageAreaManager_type_def"] = VillageAreaManager_type_def,
		["DataShortcut_type_def"] = DataShortcut_type_def,
		["EquipDataManager_type_def"] = find_type_definition("snow.data.EquipDataManager"),
		["ItemInventoryData_type_def"] = find_type_definition("snow.data.ItemInventoryData"),
		["EnemyUtility_type_def"] = find_type_definition("snow.enemy.EnemyUtility"),
		["FacilityDataManager_type_def"] = FacilityDataManager_type_def,
		["KitchenFacility_type_def"] = KitchenFacility_type_def,
		["BbqFunc_type_def"] = BbqFunc_type_def,
		["ChatManager_type_def"] = ChatManager_type_def,
		["GuiManager_type_def"] = GuiManager_type_def,
		["StmGuiInput_type_def"] = find_type_definition("snow.gui.StmGuiInput"),
		["PlayerLobbyBase_type_def"] = PlayerLobbyBase_type_def,
		["PlayerQuestBase_type_def"] = find_type_definition("snow.player.PlayerQuestBase")
	},
	["Objects"] = {
		["FadeManager"] = get_managed_singleton("snow.FadeManager"),
		["CameraManager"] = get_managed_singleton("snow.CameraManager"),
		["QuestManager"] = get_managed_singleton("snow.QuestManager"),
		["SnowGameManager"] = get_managed_singleton("snow.SnowGameManager"),
		["VillageAreaManager"] = get_managed_singleton("snow.VillageAreaManager"),
		["DemoCamera"] = get_managed_singleton("snow.camera.DemoCamera"),
		["ContentsIdDataManager"] = get_managed_singleton("snow.data.ContentsIdDataManager"),
		["EquipDataManager"] = get_managed_singleton("snow.data.EquipDataManager"),
		["FacilityDataManager"] = get_managed_singleton("snow.data.FacilityDataManager"),
		["KitchenFacility"] = nil,
		["BbqFunc"] = nil,
		["OtomoSpyUnitManager"] = get_managed_singleton("snow.data.OtomoSpyUnitManager"),
		["SkillDataManager"] = get_managed_singleton("snow.data.SkillDataManager"),
		["TradeCenterFacility"] = get_managed_singleton("snow.facility.TradeCenterFacility"),
		["ChatManager"] = get_managed_singleton("snow.gui.ChatManager"),
		["GuiManager"] = get_managed_singleton("snow.gui.GuiManager"),
		["OtomoManager"] = get_managed_singleton("snow.otomo.OtomoManager"),
		["MasterPlayerLobbyBase"] = nil,
		["PlayerManager"] = get_managed_singleton("snow.player.PlayerManager"),
		["ProgressOwlNestManager"] = get_managed_singleton("snow.progress.ProgressOwlNestManager"),
		["StagePointManager"] = get_managed_singleton("snow.stage.StagePointManager")
	},
	["on_frame"] = _G.re.on_frame,
	["Vector2f_new"] = _G.Vector2f.new,
	["Vector3f_new"] = _G.Vector3f.new,
	["TRUE_POINTER"] = TRUE_POINTER,
	["FALSE_POINTER"] = to_ptr(false),
	["Font"] = imgui.load_font("NotoSansKR-Bold.otf", 24, {
		0x0020, 0x00FF, -- Basic Latin + Latin Supplement
		0x2000, 0x206F, -- General Punctuation
		0x3000, 0x30FF, -- CJK Symbols and Punctuations, Hiragana, Katakana
		0x3130, 0x318F, -- Hangul Compatibility Jamo
		0x31F0, 0x31FF, -- Katakana Phonetic Extensions
		0xFF00, 0xFFEF, -- Half-width characters
		0x4e00, 0x9FAF, -- CJK Ideograms
		0xA960, 0xA97F, -- Hangul Jamo Extended-A
		0xAC00, 0xD7A3, -- Hangul Syllables
		0xD7B0, 0xD7FF, -- Hangul Jamo Extended-B
		0
	}),
	checkKeyTrg = function(key)
		return getTrg_method:call(nil, key);
	end,
	getVillagePoint = function()
		return get_Point_method:call(nil);
	end,
	subVillagePoint = function(count)
		subPoint_method:call(nil, count);
	end,
	SKIP_ORIGINAL_func = function()
		return SKIP_ORIGINAL;
	end,
	RETURN_TRUE_func = function()
		return TRUE_POINTER;
	end,
	to_bool = function(value)
		return (to_int64(value) & 1) == 1;
	end
};
--
function this.ClearFade()
	local FadeManager = this:get_FadeManager();
	set_FadeMode_method:call(FadeManager, 3);
	FadeManager:set_field("fadeOutInFlag", false);
end

function this:checkGameStatus(checkType)
	local SnowGameManager = self:get_SnowGameManager();
	return SnowGameManager ~= nil and checkType == get_CurrentStatus_method:call(SnowGameManager) or nil;
end

function this:getQuestMapNo()
	return getMapNo_method:call(self:get_QuestManager());
end

function this:getQuestLife()
	return getQuestLife_method:call(self:get_QuestManager());
end

function this:getDeathNum()
	return getDeathNum_method:call(self:get_QuestManager());
end

function this:SendMessage(text)
	reqAddChatInfomation_method:call(self:get_ChatManager(), text, 0); -- sound on : 2289944406
end

function this:getCountOfAll(itemId)
	return getCountOfAll_method:call(self:get_ContentsIdDataManager(), itemId);
end

function this:closeRewardDialog()
	closeRewardDialog_method:call(self:get_GuiManager());
end

function this:outputMealTicket()
	outputTicket_method:call(self:get_BbqFunc());
end
--
function this:get_FadeManager()
	if self.Objects.FadeManager == nil or self.Objects.FadeManager:get_reference_count() <= 1 then
		self.Objects.FadeManager = get_managed_singleton("snow.FadeManager");
	end

	return self.Objects.FadeManager;
end

function this:get_CameraManager()
	if self.Objects.CameraManager == nil or self.Objects.CameraManager:get_reference_count() <= 1 then
		self.Objects.CameraManager = get_managed_singleton("snow.QuestManager");
	end

	return self.Objects.CameraManager;
end

function this:get_QuestManager()
	if self.Objects.QuestManager == nil or self.Objects.QuestManager:get_reference_count() <= 1 then
		self.Objects.QuestManager = get_managed_singleton("snow.QuestManager");
	end

	return self.Objects.QuestManager;
end

function this:get_SnowGameManager()
	if self.Objects.SnowGameManager == nil or self.Objects.SnowGameManager:get_reference_count() <= 1 then
		self.Objects.SnowGameManager = get_managed_singleton("snow.SnowGameManager");
	end

	return self.Objects.SnowGameManager;
end

function this:get_VillageAreaManager()
	return self.Objects.VillageAreaManager;
end

function this:get_DemoCamera()
	if self.Objects.DemoCamera == nil or self.Objects.DemoCamera:get_reference_count() <= 1 then
		self.Objects.DemoCamera = get_managed_singleton("snow.camera.DemoCamera");
	end

	return self.Objects.DemoCamera;
end

function this:get_ContentsIdDataManager()
	if self.Objects.ContentsIdDataManager == nil or self.Objects.ContentsIdDataManager:get_reference_count() <= 1 then
		self.Objects.ContentsIdDataManager = get_managed_singleton("snow.data.ContentsIdDataManager");
	end

	return self.Objects.ContentsIdDataManager;
end

function this:get_EquipDataManager()
	if self.Objects.EquipDataManager == nil or self.Objects.EquipDataManager:get_reference_count() <= 1 then
		self.Objects.EquipDataManager = get_managed_singleton("snow.data.EquipDataManager");
	end

	return self.Objects.EquipDataManager;
end

function this:get_FacilityDataManager()
	if self.Objects.FacilityDataManager == nil or self.Objects.FacilityDataManager:get_reference_count() <= 1 then
		self.Objects.FacilityDataManager = get_managed_singleton("snow.data.FacilityDataManager");
	end

	return self.Objects.FacilityDataManager;
end

function this:get_KitchenFacility()
	if self.Objects.KitchenFacility == nil or self.Objects.KitchenFacility:get_reference_count() <= 1 then
		self.Objects.KitchenFacility = get_Kitchen_method:call(self:get_FacilityDataManager());
	end

	return self.Objects.KitchenFacility;
end

function this:get_BbqFunc()
	if self.Objects.BbqFunc == nil or self.Objects.BbqFunc:get_reference_count() <= 1 then
		self.Objects.BbqFunc = get_BbqFunc_method:call(self:get_KitchenFacility());
	end

	return self.Objects.BbqFunc;
end

function this:get_OtomoSpyUnitManager()
	if self.Objects.OtomoSpyUnitManager == nil or self.Objects.OtomoSpyUnitManager:get_reference_count() <= 1 then
		self.Objects.OtomoSpyUnitManager = get_managed_singleton("snow.data.OtomoSpyUnitManager");
	end

	return self.Objects.OtomoSpyUnitManager;
end

function this:get_SkillDataManager()
	if self.Objects.SkillDataManager == nil or self.Objects.SkillDataManager:get_reference_count() <= 1 then
		self.Objects.SkillDataManager = get_managed_singleton("snow.data.SkillDataManager");
	end

	return self.Objects.SkillDataManager;
end

function this:get_TradeCenterFacility()
	if self.Objects.TradeCenterFacility == nil or self.Objects.TradeCenterFacility:get_reference_count() <= 1 then
		self.Objects.TradeCenterFacility = get_managed_singleton("snow.facility.TradeCenterFacility");
	end

	return self.Objects.TradeCenterFacility;
end

function this:get_ChatManager()
	if self.Objects.ChatManager == nil or self.Objects.ChatManager:get_reference_count() <= 1 then
		self.Objects.ChatManager = get_managed_singleton("snow.gui.ChatManager");
	end

	return self.Objects.ChatManager;
end

function this:get_GuiManager()
	if self.Objects.GuiManager == nil or self.Objects.GuiManager:get_reference_count() <= 1 then
		self.Objects.GuiManager = get_managed_singleton("snow.gui.GuiManager");
	end

	return self.Objects.GuiManager;
end

function this:get_OtomoManager()
	if self.Objects.OtomoManager == nil or self.Objects.OtomoManager:get_reference_count() <= 1 then
		self.Objects.OtomoManager = get_managed_singleton("snow.otomo.OtomoManager");
	end

	return self.Objects.OtomoManager;
end

function this:get_MasterPlayerLobbyBase()
	return self.Objects.MasterPlayerLobbyBase;
end

function this:get_PlayerManager()
	if self.Objects.PlayerManager == nil or self.Objects.PlayerManager:get_reference_count() <= 1 then
		self.Objects.PlayerManager = get_managed_singleton("snow.player.PlayerManager");
	end

	return self.Objects.PlayerManager;
end

function this:get_ProgressOwlNestManager()
	if self.Objects.ProgressOwlNestManager == nil or self.Objects.ProgressOwlNestManager:get_reference_count() <= 1 then
		self.Objects.ProgressOwlNestManager = get_managed_singleton("snow.progress.ProgressOwlNestManager");
	end

	return self.Objects.ProgressOwlNestManager;
end

function this:get_StagePointManager()
	if self.Objects.StagePointManager == nil or self.Objects.StagePointManager:get_reference_count() <= 1 then
		self.Objects.StagePointManager = get_managed_singleton("snow.stage.StagePointManager");
	end

	return self.Objects.StagePointManager;
end
--
local PlayerLobbyBase_onDestroy_method = PlayerLobbyBase_type_def:get_method("onDestroy");

local function destroyPlayerLobbyBase()
	this.Objects.MasterPlayerLobbyBase = nil;
end

local function getPlayerLobbyBase(args)
	local MasterPlayerLobbyBase = to_managed_object(args[2]);
	this.Objects.MasterPlayerLobbyBase = MasterPlayerLobbyBase;
	hook_vtable(MasterPlayerLobbyBase, PlayerLobbyBase_onDestroy_method, nil, destroyPlayerLobbyBase);
end

local function getPlayerLobbyBaseFromUpdate(args)
	if this.Objects.MasterPlayerLobbyBase == nil then
		getPlayerLobbyBase(args);
	end
end

hook(PlayerLobbyBase_type_def:get_method("start"), getPlayerLobbyBase);
hook(PlayerLobbyBase_type_def:get_method("update"), getPlayerLobbyBaseFromUpdate);
--
local VillageAreaManager_onDestroy_method = VillageAreaManager_type_def:get_method("onDestroy");

local function VillageAreaManager_onDestroy()
	this.Objects.VillageAreaManager = nil;
end

local function getVillageAreaManager(args)
	local VillageAreaManager = to_managed_object(args[2]);
	this.Objects.VillageAreaManager = VillageAreaManager;
	hook_vtable(VillageAreaManager, VillageAreaManager_onDestroy_method, nil, VillageAreaManager_onDestroy);
end

local function VillageAreaManager_update(args)
	if this.Objects.VillageAreaManager == nil then
		getVillageAreaManager(args);
	end
end

hook(VillageAreaManager_type_def:get_method("start"), getVillageAreaManager);
hook(VillageAreaManager_type_def:get_method("update"), VillageAreaManager_update);
--
return this;