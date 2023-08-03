local math = math;
local string = string;

local imgui = imgui;
local load_font = imgui.load_font;

local sdk = sdk;
local to_ptr = sdk.to_ptr;
local to_int64 = sdk.to_int64;
local find_type_definition = sdk.find_type_definition;
local get_managed_singleton = sdk.get_managed_singleton;
local PreHookResult = sdk.PreHookResult;
local SKIP_ORIGINAL = PreHookResult.SKIP_ORIGINAL;

local re = re;

local Vector2f = Vector2f;
local Vector3f = Vector3f;
local ValueType = ValueType;

local TRUE_POINTER = to_ptr(true);
local QuestManager_type_def = find_type_definition("snow.QuestManager");

local this = {
    lua = {
        pairs = pairs,
        ipairs = ipairs,
        tostring = tostring,
        math_min = math.min,
        math_max = math.max,
        string_format = string.format
    },
    sdk = {
        hook = sdk.hook,
        hook_vtable = sdk.hook_vtable,
        find_type_definition = find_type_definition,
        get_managed_singleton = get_managed_singleton,
        to_managed_object = sdk.to_managed_object,
        to_ptr = to_ptr,
        to_int64 = to_int64,
        to_float = sdk.to_float,
        to_valuetype = sdk.to_valuetype,
        SKIP_ORIGINAL = SKIP_ORIGINAL,
        CALL_ORIGINAL = PreHookResult.CALL_ORIGINAL
    },
    imgui = {
        load_font = load_font,
        push_font = imgui.push_font,
        pop_font = imgui.pop_font,
        begin_window = imgui.begin_window,
        end_window = imgui.end_window,
        begin_table = imgui.begin_table,
        table_setup_column = imgui.table_setup_column,
        table_next_column = imgui.table_next_column,
        table_headers_row = imgui.table_headers_row,
        table_next_row = imgui.table_next_row,
        end_table = imgui.end_table,
        text = imgui.text,
        text_colored = imgui.text_colored,
        spacing = imgui.spacing
    },
    re = {
        on_frame = re.on_frame
    },
    Vector2f = {
        new = Vector2f.new
    },
    Vector3f = {
        new = Vector3f.new
    },
    ValueType = {
        new = ValueType.new
    },
    isOnVillageStarted = false,
    TRUE_POINTER = TRUE_POINTER,
    FALSE_POINTER = to_ptr(false),
    Font = load_font("NotoSansKR-Bold.otf", 22, {
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
    type_definitions = {
        Application_type_def = find_type_definition("via.Application"),
        CameraManager_type_def = find_type_definition("snow.CameraManager"),
        QuestManager_type_def = QuestManager_type_def,
        VillageAreaManager_type_def = find_type_definition("snow.VillageAreaManager"),
        ItemId_type_def = find_type_definition("snow.data.ContentsIdSystem.ItemId"),
        DataManager_type_def = find_type_definition("snow.data.DataManager"),
        EquipDataManager_type_def = find_type_definition("snow.data.EquipDataManager"),
        GuiManager_type_def = find_type_definition("snow.gui.GuiManager"),
        StmGuiInput_type_def = find_type_definition("snow.gui.StmGuiInput"),
        PlayerManager_type_def = find_type_definition("snow.player.PlayerManager"),
        WwiseChangeSpaceWatcher_type_def = find_type_definition("snow.wwise.WwiseChangeSpaceWatcher")
    },

    Keys = {
        Home_key = false,
        F5_key = false,
        F6_Key = false
    },
    checkKeyTrg = false,

    GameStatusType = {
        Village = false,
        Quest = false
    },
    checkGameStatus = false,

    QuestStatus = {
        Success = false
    },
    checkQuestStatus = false,

    ClearFade = false,

    QuestMapList = {
        ShrineRuins = false,
        SandyPlains = false,
        FloodedForest = false,
        FrostIslands = false,
        LavaCaverns = false,
        Jungle = false,
        Citadel = false
    },
    getQuestMapNo = false,

    getQuestLife = false,
    getDeathNum = false,

    SendMessage = false,

    SKIP_ORIGINAL = function()
        return SKIP_ORIGINAL;
    end,

    RETURN_TRUE = function()
        return TRUE_POINTER;
    end,

    to_bool = function(value)
        return (to_int64(value) & 1) == 1;
    end,

    to_byte = function(value)
        return to_int64(value) & 0xFF;
    end,

    to_uint = function(value)
        return to_int64(value) & 0xFFFFFFFF;
    end
};
--
local getTrg_method = find_type_definition("snow.GameKeyboard.HardwareKeyboard"):get_method("getTrg(via.hid.KeyboardKey)"); -- static

local KeyboardKey_type_def = find_type_definition("via.hid.KeyboardKey");
this.Keys.Home_key = KeyboardKey_type_def:get_field("Home"):get_data(nil);
this.Keys.F5_key = KeyboardKey_type_def:get_field("F5"):get_data(nil);
this.Keys.F6_key = KeyboardKey_type_def:get_field("F6"):get_data(nil);

this.checkKeyTrg = function(key)
    return getTrg_method:call(nil, key);
end
--
local get_CurrentStatus_method = find_type_definition("snow.SnowGameManager"):get_method("get_CurrentStatus");

local GameStatusType_type_def = get_CurrentStatus_method:get_return_type();
this.GameStatusType.Village = GameStatusType_type_def:get_field("Village"):get_data(nil);
this.GameStatusType.Quest = GameStatusType_type_def:get_field("Quest"):get_data(nil);

this.checkGameStatus = function(checkType)
    local SnowGameManager = get_managed_singleton("snow.SnowGameManager");
    if SnowGameManager ~= nil then
        return checkType == get_CurrentStatus_method:call(SnowGameManager);
    end

    return nil;
end
--
local checkStatus_method = QuestManager_type_def:get_method("checkStatus(snow.QuestManager.Status)");

this.QuestStatus.Success = find_type_definition("snow.QuestManager.Status"):get_field("Success"):get_data(nil);

this.checkQuestStatus = function(nullable_questManager, checkType)
    if nullable_questManager == nil then
        nullable_questManager = get_managed_singleton("snow.QuestManager");
    end

    return checkStatus_method:call(nullable_questManager, checkType);
end
--
local set_FadeMode_method = find_type_definition("snow.FadeManager"):get_method("set_FadeMode(snow.FadeManager.MODE)");
local FadeMode_FINISH = find_type_definition("snow.FadeManager.MODE"):get_field("FINISH"):get_data(nil);

this.ClearFade = function()
    local FadeManager = get_managed_singleton("snow.FadeManager");
    set_FadeMode_method:call(FadeManager, FadeMode_FINISH);
    FadeManager:set_field("fadeOutInFlag", false);
end
--
local getMapNo_method = QuestManager_type_def:get_method("getMapNo");

local MapNoType_type_def = getMapNo_method:get_return_type();
this.QuestMapList.ShrineRuins = MapNoType_type_def:get_field("No01"):get_data(nil); -- 사원 폐허
this.QuestMapList.SandyPlains = MapNoType_type_def:get_field("No02"):get_data(nil); -- 모래 평원
this.QuestMapList.FloodedForest = MapNoType_type_def:get_field("No03"):get_data(nil); -- 수몰된 숲
this.QuestMapList.FrostIslands = MapNoType_type_def:get_field("No04"):get_data(nil); -- 한랭 군도
this.QuestMapList.LavaCaverns = MapNoType_type_def:get_field("No05"):get_data(nil); -- 용암 동굴
this.QuestMapList.Jungle = MapNoType_type_def:get_field("No31"):get_data(nil); -- 밀림
this.QuestMapList.Citadel = MapNoType_type_def:get_field("No32"):get_data(nil);  -- 요새 고원

this.getQuestMapNo = function(nullable_questManager)
    if nullable_questManager == nil then
        nullable_questManager = get_managed_singleton("snow.QuestManager");
    end

    return getMapNo_method:call(nullable_questManager);
end
--
local getQuestLife_method = QuestManager_type_def:get_method("getQuestLife");
local getDeathNum_method = QuestManager_type_def:get_method("getDeathNum");

this.getQuestLife = function(nullable_questManager)
    if nullable_questManager == nil then
        nullable_questManager = get_managed_singleton("snow.QuestManager");
    end

    return getQuestLife_method:call(nullable_questManager);
end

this.getDeathNum = function(nullable_questManager)
    if nullable_questManager == nil then
        nullable_questManager = get_managed_singleton("snow.QuestManager");
    end

    return getDeathNum_method:call(nullable_questManager);
end
--
local reqAddChatInfomation_method = find_type_definition("snow.gui.ChatManager"):get_method("reqAddChatInfomation(System.String, System.UInt32)");

this.SendMessage = function(nullable_chatManager, text)
    if nullable_chatManager == nil then
        nullable_chatManager = get_managed_singleton("snow.gui.ChatManager");
    end

    reqAddChatInfomation_method:call(nullable_chatManager, text, 2289944406);
end
--
return this;