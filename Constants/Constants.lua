local this = {
	lua = {},
	sdk = {},
	imgui = {},
	re = {},
	Vector2f = {},
	Vector3f = {},
	type_definitions = {},
	Objects = {}
};
--
local _G = _G;

local math = _G.math;
local string = _G.string;

this.lua.pairs = _G.pairs;
this.lua.tostring = _G.tostring;
this.lua.math_min = math.min;
this.lua.math_max = math.max;
this.lua.string_format = string.format;
--
local sdk = _G.sdk;
local hook = sdk.hook;
local hook_vtable = sdk.hook_vtable;
local find_type_definition = sdk.find_type_definition;
local get_managed_singleton = sdk.get_managed_singleton;
local to_managed_object = sdk.to_managed_object;
local to_ptr = sdk.to_ptr;
local to_int64 = sdk.to_int64;
local PreHookResult = sdk.PreHookResult;
local SKIP_ORIGINAL = PreHookResult.SKIP_ORIGINAL;

this.sdk.create_managed_array = sdk.create_managed_array;
this.sdk.hook = hook;
this.sdk.hook_vtable = hook_vtable;
this.sdk.find_type_definition = find_type_definition;
this.sdk.get_managed_singleton = get_managed_singleton;
this.sdk.to_managed_object = to_managed_object;
this.sdk.to_ptr = to_ptr;
this.sdk.to_int64 = to_int64;
this.sdk.to_float = sdk.to_float;
this.sdk.to_valuetype = sdk.to_valuetype;
this.sdk.SKIP_ORIGINAL = SKIP_ORIGINAL;
this.sdk.CALL_ORIGINAL = PreHookResult.CALL_ORIGINAL;
--
local imgui = _G.imgui;
local load_font = imgui.load_font;

this.imgui.push_font = imgui.push_font;
this.imgui.begin_window = imgui.begin_window;
this.imgui.end_window = imgui.end_window;
this.imgui.begin_table = imgui.begin_table;
this.imgui.table_setup_column = imgui.table_setup_column;
this.imgui.table_next_column = imgui.table_next_column;
this.imgui.table_headers_row = imgui.table_headers_row;
this.imgui.table_next_row = imgui.table_next_row;
this.imgui.end_table = imgui.end_table;
this.imgui.text = imgui.text;
this.imgui.text_colored = imgui.text_colored;
this.imgui.spacing = imgui.spacing;
--
local re = _G.re;

this.re.on_frame = re.on_frame;
--
local Vector2f = _G.Vector2f;

this.Vector2f.new = Vector2f.new;
--
local Vector3f = _G.Vector3f;

this.Vector3f.new = Vector3f.new;
--
local TRUE_POINTER = to_ptr(true);

this.TRUE_POINTER = TRUE_POINTER;
this.FALSE_POINTER = to_ptr(false);
--
local QuestManager_type_def = find_type_definition("snow.QuestManager");
local FacilityDataManager_type_def = find_type_definition("snow.data.FacilityDataManager");

this.type_definitions.Application_type_def = find_type_definition("via.Application");
this.type_definitions.CameraManager_type_def = find_type_definition("snow.CameraManager");
this.type_definitions.QuestManager_type_def = QuestManager_type_def;
this.type_definitions.VillageAreaManager_type_def = find_type_definition("snow.VillageAreaManager");
this.type_definitions.DataManager_type_def = find_type_definition("snow.data.DataManager");
this.type_definitions.EquipDataManager_type_def = find_type_definition("snow.data.EquipDataManager");
this.type_definitions.FacilityDataManager_type_def = FacilityDataManager_type_def;
this.type_definitions.EnemyUtility_type_def = find_type_definition("snow.enemy.EnemyUtility");
this.type_definitions.GuiManager_type_def = find_type_definition("snow.gui.GuiManager");
this.type_definitions.StmGuiInput_type_def = find_type_definition("snow.gui.StmGuiInput");
this.type_definitions.PlayerQuestBase_type_def = find_type_definition("snow.player.PlayerQuestBase");
this.type_definitions.WwiseChangeSpaceWatcher_type_def = find_type_definition("snow.wwise.WwiseChangeSpaceWatcher");
--
this.Font = load_font("NotoSansKR-Bold.otf", 24, {
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
});
--
local getTrg_method = find_type_definition("snow.GameKeyboard.HardwareKeyboard"):get_method("getTrg(via.hid.KeyboardKey)"); -- static

function this.checkKeyTrg(key)
	return getTrg_method:call(nil, key);
end
--
local get_CurrentStatus_method = find_type_definition("snow.SnowGameManager"):get_method("get_CurrentStatus");

function this.checkGameStatus(checkType)
	local SnowGameManager = this:get_SnowGameManager();
	return SnowGameManager ~= nil and checkType == get_CurrentStatus_method:call(SnowGameManager) or nil;
end
--
local set_FadeMode_method = find_type_definition("snow.FadeManager"):get_method("set_FadeMode(snow.FadeManager.MODE)");

function this.ClearFade()
	local FadeManager = this:get_FadeManager();
	set_FadeMode_method:call(FadeManager, 3);
	FadeManager:set_field("fadeOutInFlag", false);
end
--
local getMasterPlayerBase_method = find_type_definition("snow.npc.NpcUtility"):get_method("getMasterPlayer"); -- static
this.type_definitions.PlayerBase_type_def = getMasterPlayerBase_method:get_return_type();

function this:get_MasterPlayerBase()
	if self.Objects.MasterPlayerBase == nil then
		self.Objects.MasterPlayerBase = getMasterPlayerBase_method:call(nil);
	end

	return self.Objects.MasterPlayerBase;
end
--
local get_Kitchen_method = FacilityDataManager_type_def:get_method("get_Kitchen");
this.type_definitions.KitchenFacility_type_def = get_Kitchen_method:get_return_type();

function this:get_KitchenFacility()
	if self.Objects.KitchenFacility == nil then
		self.Objects.KitchenFacility = get_Kitchen_method:call(this:get_FacilityDataManager());
	end

	return self.Objects.KitchenFacility;
end
--
local getMapNo_method = QuestManager_type_def:get_method("getMapNo");

this.QuestMapList = {
	ShrineRuins = 1,
	SandyPlains = 2,
	FloodedForest = 3,
	FrostIslands = 4,
	LavaCaverns = 5,
	Jungle = 12,
	Citadel = 13
};

function this:getQuestMapNo()
	return getMapNo_method:call(self:get_QuestManager());
end
--
local getQuestLife_method = QuestManager_type_def:get_method("getQuestLife");
local getDeathNum_method = QuestManager_type_def:get_method("getDeathNum");

function this:getQuestLife()
	return getQuestLife_method:call(self:get_QuestManager());
end

function this:getDeathNum()
	return getDeathNum_method:call(self:get_QuestManager());
end
--
local reqAddChatInfomation_method = find_type_definition("snow.gui.ChatManager"):get_method("reqAddChatInfomation(System.String, System.UInt32)");

function this:SendMessage(text)
	reqAddChatInfomation_method:call(self:get_ChatManager(), text, 0); -- sound on : 2289944406
end
--
function this.SKIP_ORIGINAL_func()
	return SKIP_ORIGINAL;
end

function this.RETURN_TRUE_func()
	return TRUE_POINTER;
end

function this.to_bool(value)
	return (to_int64(value) & 1) == 1;
end
--
function this:get_CameraManager()
	if self.Objects.CameraManager == nil or self.Objects.CameraManager:get_reference_count() <= 1 then
		self.Objects.CameraManager = get_managed_singleton("snow.CameraManager");
	end

	return self.Objects.CameraManager;
end

function this:get_FadeManager()
	if self.Objects.FadeManager == nil or self.Objects.FadeManager:get_reference_count() <= 1 then
		self.Objects.FadeManager = get_managed_singleton("snow.FadeManager");
	end

	return self.Objects.FadeManager;
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
	if self.Objects.VillageAreaManager == nil or self.Objects.VillageAreaManager:get_reference_count() <= 1 then
		self.Objects.VillageAreaManager = get_managed_singleton("snow.VillageAreaManager");
	end

	return self.Objects.VillageAreaManager;
end

function this:get_DemoCamera()
	if self.Objects.DemoCamera == nil or self.Objects.DemoCamera:get_reference_count() <= 1 then
		self.Objects.DemoCamera = get_managed_singleton("snow.camera.DemoCamera");
	end

	return self.Objects.DemoCamera;
end

function this:get_DataManager()
	if self.Objects.DataManager == nil or self.Objects.DataManager:get_reference_count() <= 1 then
		self.Objects.DataManager = get_managed_singleton("snow.data.DataManager");
	end

	return self.Objects.DataManager;
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

function this:get_PlayerManager()
	if self.Objects.PlayerManager == nil or self.Objects.PlayerManager:get_reference_count() <= 1 then
		self.Objects.PlayerManager = get_managed_singleton("snow.player.PlayerManager");
	end

	return self.Objects.PlayerManager;
end

--[[function this:get_ProgressEc019UnlockItemManager()
	if self.Objects.ProgressEc019UnlockItemManager == nil or self.Objects.ProgressEc019UnlockItemManager:get_reference_count() <= 1 then
		self.Objects.ProgressEc019UnlockItemManager = get_managed_singleton("snow.progress.ProgressEc019UnlockItemManager");
	end

	return self.Objects.ProgressEc019UnlockItemManager;
end]]

function this:get_ProgressGoodRewardManager()
	if self.Objects.ProgressGoodRewardManager == nil or self.Objects.ProgressGoodRewardManager:get_reference_count() <= 1 then
		self.Objects.ProgressGoodRewardManager = get_managed_singleton("snow.progress.ProgressGoodRewardManager");
	end

	return self.Objects.ProgressGoodRewardManager;
end

--[[function this:get_ProgressNoteRewardManager()
	if self.Objects.ProgressNoteRewardManager == nil or self.Objects.ProgressNoteRewardManager:get_reference_count() <= 1 then
		self.Objects.ProgressNoteRewardManager = get_managed_singleton("snow.progress.ProgressNoteRewardManager");
	end

	return self.Objects.ProgressNoteRewardManager;
end]]

function this:get_ProgressOtomoTicketManager()
	if self.Objects.ProgressOtomoTicketManager == nil or self.Objects.ProgressOtomoTicketManager:get_reference_count() <= 1 then
		self.Objects.ProgressOtomoTicketManager = get_managed_singleton("snow.progress.ProgressOtomoTicketManager");
	end

	return self.Objects.ProgressOtomoTicketManager;
end

function this:get_ProgressOwlNestManager()
	if self.Objects.ProgressOwlNestManager == nil or self.Objects.ProgressOwlNestManager:get_reference_count() <= 1 then
		self.Objects.ProgressOwlNestManager = get_managed_singleton("snow.progress.ProgressOwlNestManager");
	end

	return self.Objects.ProgressOwlNestManager;
end

--[[function this:get_ProgressSwitchActionSupplyManager()
	if self.Objects.ProgressSwitchActionSupplyManager == nil or self.Objects.ProgressSwitchActionSupplyManager:get_reference_count() <= 1 then
		self.Objects.ProgressSwitchActionSupplyManager = get_managed_singleton("snow.progress.ProgressSwitchActionSupplyManager");
	end

	return self.Objects.ProgressSwitchActionSupplyManager;
end]]

function this:get_ProgressTicketSupplyManager()
	if self.Objects.ProgressTicketSupplyManager == nil or self.Objects.ProgressTicketSupplyManager:get_reference_count() <= 1 then
		self.Objects.ProgressTicketSupplyManager = get_managed_singleton("snow.progress.ProgressTicketSupplyManager");
	end

	return self.Objects.ProgressTicketSupplyManager;
end

function this:get_StagePointManager()
	if self.Objects.StagePointManager == nil or self.Objects.StagePointManager:get_reference_count() <= 1 then
		self.Objects.StagePointManager = get_managed_singleton("snow.stage.StagePointManager");
	end

	return self.Objects.StagePointManager;
end
--
return this;