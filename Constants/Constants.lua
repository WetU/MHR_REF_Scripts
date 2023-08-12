local _G = _G;

local pairs = _G.pairs;
local tostring = _G.tostring;

local math = _G.math;
local math_min = math.min;
local math_max = math.max;

local string = _G.string;
local string_format = string.format;
--
local sdk = _G.sdk;
local create_managed_array = sdk.create_managed_array;
local hook = sdk.hook;
local hook_vtable = sdk.hook_vtable;
local find_type_definition = sdk.find_type_definition;
local get_managed_singleton = sdk.get_managed_singleton;
local to_managed_object = sdk.to_managed_object;
local to_ptr = sdk.to_ptr;
local to_int64 = sdk.to_int64;
local to_float = sdk.to_float;
local to_valuetype = sdk.to_valuetype;
local PreHookResult = sdk.PreHookResult;
local SKIP_ORIGINAL = PreHookResult.SKIP_ORIGINAL;
local CALL_ORIGINAL = PreHookResult.CALL_ORIGINAL;
--
local imgui = _G.imgui;
local load_font = imgui.load_font;
local push_font = imgui.push_font;
local begin_window = imgui.begin_window;
local end_window = imgui.end_window;
local begin_table = imgui.begin_table;
local table_setup_column = imgui.table_setup_column;
local table_next_column = imgui.table_next_column;
local table_headers_row = imgui.table_headers_row;
local table_next_row = imgui.table_next_row;
local end_table = imgui.end_table;
local text = imgui.text;
local text_colored = imgui.text_colored;
local spacing = imgui.spacing;
--
local re = _G.re;
local on_frame = re.on_frame;
--
local Vector2f = _G.Vector2f;
local Vector2f_new = Vector2f.new;

local Vector3f = _G.Vector3f;
local Vector3f_new = Vector3f.new;
--
local TRUE_POINTER = to_ptr(true);
local FALSE_POINTER = to_ptr(false);
--
local Application_type_def = find_type_definition("via.Application");
local CameraManager_type_def = find_type_definition("snow.CameraManager");
local QuestManager_type_def = find_type_definition("snow.QuestManager");
local VillageAreaManager_type_def = find_type_definition("snow.VillageAreaManager");
local DataManager_type_def = find_type_definition("snow.data.DataManager");
local EquipDataManager_type_def = find_type_definition("snow.data.EquipDataManager");
local FacilityDataManager_type_def = find_type_definition("snow.data.FacilityDataManager");
local EnemyUtility_type_def = find_type_definition("snow.enemy.EnemyUtility");
local GuiManager_type_def = find_type_definition("snow.gui.GuiManager");
local StmGuiInput_type_def = find_type_definition("snow.gui.StmGuiInput");
local WwiseChangeSpaceWatcher_type_def = find_type_definition("snow.wwise.WwiseChangeSpaceWatcher");
--
local Font = load_font("NotoSansKR-Bold.otf", 24, {
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

local function checkKeyTrg(key)
	return getTrg_method:call(nil, key);
end
--
local get_CurrentStatus_method = find_type_definition("snow.SnowGameManager"):get_method("get_CurrentStatus");

local function checkGameStatus(checkType)
	local SnowGameManager = get_managed_singleton("snow.SnowGameManager");
	return SnowGameManager ~= nil and checkType == get_CurrentStatus_method:call(SnowGameManager) or nil;
end
--
local set_FadeMode_method = find_type_definition("snow.FadeManager"):get_method("set_FadeMode(snow.FadeManager.MODE)");
local FadeMode_FINISH = 3;

local function ClearFade()
	local FadeManager = get_managed_singleton("snow.FadeManager");
	set_FadeMode_method:call(FadeManager, FadeMode_FINISH);
	FadeManager:set_field("fadeOutInFlag", false);
end
--
local getMasterPlayer_method = find_type_definition("snow.npc.NpcUtility"):get_method("getMasterPlayer"); -- static
local PlayerBase_type_def = getMasterPlayer_method:get_return_type();

local function getMasterPlayerBase()
	return getMasterPlayer_method:call(nil);
end
--
local get_Kitchen_method = FacilityDataManager_type_def:get_method("get_Kitchen");
local KitchenFacility_type_def = get_Kitchen_method:get_return_type();

local function getKitchenFacility()
	return get_Kitchen_method:call(get_managed_singleton("snow.data.FacilityDataManager"));
end
--
local getMapNo_method = QuestManager_type_def:get_method("getMapNo");

local QuestMapList = {
	ShrineRuins = 1,
	SandyPlains = 2,
	FloodedForest = 3,
	FrostIslands = 4,
	LavaCaverns = 5,
	Jungle = 12,
	Citadel = 13
};

local function getQuestMapNo(nullable_questManager)
	return nullable_questManager ~= nil and getMapNo_method:call(nullable_questManager) or getMapNo_method:call(get_managed_singleton("snow.QuestManager"));
end
--
local getQuestLife_method = QuestManager_type_def:get_method("getQuestLife");
local getDeathNum_method = QuestManager_type_def:get_method("getDeathNum");

local function getQuestLife(nullable_questManager)
	return nullable_questManager ~= nil and getQuestLife_method:call(nullable_questManager) or getQuestLife_method:call(get_managed_singleton("snow.QuestManager"));
end

local function getDeathNum(nullable_questManager)
	return nullable_questManager ~= nil and getDeathNum_method:call(nullable_questManager) or getDeathNum_method:call(get_managed_singleton("snow.QuestManager"));
end
--
local reqAddChatInfomation_method = find_type_definition("snow.gui.ChatManager"):get_method("reqAddChatInfomation(System.String, System.UInt32)");

local function SendMessage(nullable_chatManager, text)
	if nullable_chatManager == nil then
		nullable_chatManager = get_managed_singleton("snow.gui.ChatManager");
	end

	reqAddChatInfomation_method:call(nullable_chatManager, text, 0); -- sound on : 2289944406
end
--
local function SKIP_ORIGINAL_func()
	return SKIP_ORIGINAL;
end

local function RETURN_TRUE_func()
	return TRUE_POINTER;
end

local function to_bool(value)
	return (to_int64(value) & 1) == 1;
end
--
local this = {
	lua = {
		pairs = pairs,
		tostring = tostring,
		math_min = math_min,
		math_max = math_max,
		string_format = string_format
	},

	sdk = {
		create_managed_array = create_managed_array,
		hook = hook,
		hook_vtable = hook_vtable,
		find_type_definition = find_type_definition,
		get_managed_singleton = get_managed_singleton,
		to_managed_object = to_managed_object,
		to_ptr = to_ptr,
		to_int64 = to_int64,
		to_float = to_float,
		to_valuetype = to_valuetype,
		SKIP_ORIGINAL = SKIP_ORIGINAL,
		CALL_ORIGINAL = CALL_ORIGINAL
	},

	imgui = {
		push_font = push_font,
		begin_window = begin_window,
		end_window = end_window,
		begin_table = begin_table,
		table_setup_column = table_setup_column,
		table_next_column = table_next_column,
		table_headers_row = table_headers_row,
		table_next_row = table_next_row,
		end_table = end_table,
		text = text,
		text_colored = text_colored,
		spacing = spacing
	},

	re = {
		on_frame = on_frame
	},

	Vector2f = {
		new = Vector2f_new
	},

	Vector3f = {
		new = Vector3f_new
	},

	TRUE_POINTER = TRUE_POINTER,
	FALSE_POINTER = FALSE_POINTER,

	Font = Font,

	type_definitions = {
		Application_type_def = Application_type_def,
		CameraManager_type_def = CameraManager_type_def,
		QuestManager_type_def = QuestManager_type_def,
		VillageAreaManager_type_def = VillageAreaManager_type_def,
		DataManager_type_def = DataManager_type_def,
		EquipDataManager_type_def = EquipDataManager_type_def,
		FacilityDataManager_type_def = FacilityDataManager_type_def,
		EnemyUtility_type_def = EnemyUtility_type_def,
		KitchenFacility_type_def = KitchenFacility_type_def,
		GuiManager_type_def = GuiManager_type_def,
		StmGuiInput_type_def = StmGuiInput_type_def,
		PlayerBase_type_def = PlayerBase_type_def,
		WwiseChangeSpaceWatcher_type_def = WwiseChangeSpaceWatcher_type_def
	},

	checkKeyTrg = checkKeyTrg,
	
	checkGameStatus = checkGameStatus,

	ClearFade = ClearFade,

	getMasterPlayerBase = getMasterPlayerBase,

	getKitchenFacility = getKitchenFacility,
	
	QuestMapList = QuestMapList,
	getQuestMapNo = getQuestMapNo,

	getQuestLife = getQuestLife,
	getDeathNum = getDeathNum,

	SendMessage = SendMessage,

	SKIP_ORIGINAL_func = SKIP_ORIGINAL_func,

	RETURN_TRUE_func = RETURN_TRUE_func,

	to_bool = to_bool
};
--
return this;