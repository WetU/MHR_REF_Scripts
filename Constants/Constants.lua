local table = table;
local string = string;
local math = math;
local sdk = sdk;
local imgui = imgui;
local Vector2f = Vector2f;
local Vector3f = Vector3f;
local ValueType = ValueType;
local re = re;

local this = {
    LUA = {
        type = type,
        pairs = pairs,
        tostring = tostring,

        table_insert = table.insert,

        string_format = string.format,

        math_min = math.min,
        math_max = math.max
    },
    SDK = {
        is_managed_object = sdk.is_managed_object,
        find_type_definition = sdk.find_type_definition,
        get_managed_singleton = sdk.get_managed_singleton,
        to_managed_object = sdk.to_managed_object,
        hook = sdk.hook,
        hook_vtable = sdk.hook_vtable,
        to_ptr = sdk.to_ptr,
        to_int64 = sdk.to_int64,
        to_float = sdk.to_float,
        SKIP_ORIGINAL = sdk.PreHookResult.SKIP_ORIGINAL,
        CALL_ORIGINAL = sdk.PreHookResult.CALL_ORIGINAL
    },
    IMGUI = {
        load_font = imgui.load_font,
        push_font = imgui.push_font,
        pop_font = imgui.pop_font,
        text = imgui.text,
        text_colored = imgui.text_colored,
        begin_window = imgui.begin_window,
        end_window = imgui.end_window,
        begin_table = imgui.begin_table,
        table_setup_column = imgui.table_setup_column,
        table_next_column = imgui.table_next_column,
        table_headers_row = imgui.table_headers_row,
        table_next_row = imgui.table_next_row,
        end_table = imgui.end_table,
        spacing = imgui.spacing
    },
    VECTOR2f = {
        new = Vector2f.new
    },
    VECTOR3f = {
        new = Vector3f.new
    },
    VALUETYPE = {
        new = ValueType.new
    },
    RE = {
        on_frame = re.on_frame,
        on_script_reset = re.on_script_reset
    },
    MasterPlayerIndex = nil,
    isOnVillageStarted = false
};

this.TRUE_POINTER = this.SDK.to_ptr(true);
this.FALSE_POINTER = this.SDK.to_ptr(false);
this.Font = this.IMGUI.load_font("NotoSansKR-Bold.otf", 22, {
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

this.type_definitions = {
    CameraManager_type_def = this.SDK.find_type_definition("snow.CameraManager"),
    QuestManager_type_def = this.SDK.find_type_definition("snow.QuestManager"),
    DataManager_type_def = this.SDK.find_type_definition("snow.data.DataManager"),
    EquipDataManager_type_def = this.SDK.find_type_definition("snow.data.EquipDataManager"),
    GuiManager_type_def = this.SDK.find_type_definition("snow.gui.GuiManager"),
    StmGuiInput_type_def = this.SDK.find_type_definition("snow.gui.StmGuiInput"),
    PlayerManager_type_def = this.SDK.find_type_definition("snow.player.PlayerManager"),
    WwiseChangeSpaceWatcher_type_def = this.SDK.find_type_definition("snow.wwise.WwiseChangeSpaceWatcher")
};
--
local get_CurrentStatus_method = this.SDK.find_type_definition("snow.SnowGameManager"):get_method("get_CurrentStatus");
local GameStatusType_type_def = get_CurrentStatus_method:get_return_type();
this.GameStatusType = {
    Village = GameStatusType_type_def:get_field("Village"):get_data(nil),
    Quest = GameStatusType_type_def:get_field("Quest"):get_data(nil)
};
--
local getMapNo_method = this.type_definitions.QuestManager_type_def:get_method("getMapNo");
local MapNoType_type_def = getMapNo_method:get_return_type();
this.QuestMapList = {
    ["Shrine Ruins"] = MapNoType_type_def:get_field("No01"):get_data(nil), -- 사원 폐허
    ["Sandy Plains"] = MapNoType_type_def:get_field("No02"):get_data(nil), -- 모래 평원
    ["Flooded Forest"] = MapNoType_type_def:get_field("No03"):get_data(nil), -- 수몰된 숲
    ["Frost Islands"] = MapNoType_type_def:get_field("No04"):get_data(nil), -- 한랭 군도
    ["Lava Caverns"] = MapNoType_type_def:get_field("No05"):get_data(nil), -- 용암 동굴
    ["Jungle"] = MapNoType_type_def:get_field("No31"):get_data(nil), -- 밀림
    ["Citadel"] = MapNoType_type_def:get_field("No32"):get_data(nil)  -- 요새 고원
};

local checkStatus_method = this.type_definitions.QuestManager_type_def:get_method("checkStatus(snow.QuestManager.Status)");
this.QuestStatus = {
    Success = this.SDK.find_type_definition("snow.QuestManager.Status"):get_field("Success"):get_data(nil)
};
--
local getMasterPlayerID_method = this.type_definitions.PlayerManager_type_def:get_method("getMasterPlayerID");
--
local set_FadeMode_method = this.SDK.find_type_definition("snow.FadeManager"):get_method("set_FadeMode(snow.FadeManager.MODE)");
local FadeMode_FINISH = this.SDK.find_type_definition("snow.FadeManager.MODE"):get_field("FINISH"):get_data(nil);
--
local GetTransform_method = this.type_definitions.CameraManager_type_def:get_method("GetTransform(snow.CameraManager.GameObjectType)");
local get_Position_method = GetTransform_method:get_return_type():get_method("get_Position");

local GameObjectType_MasterPlayer = this.SDK.find_type_definition("snow.CameraManager.GameObjectType"):get_field("MasterPlayer"):get_data(nil);
--
function this.GetMasterPlayerId(idx)
    if idx ~= nil then
        this.MasterPlayerIndex = idx;
        return;
    else
        local PlayerManager = this.SDK.get_managed_singleton("snow.player.PlayerManager");
        if PlayerManager ~= nil then
            this.MasterPlayerIndex = getMasterPlayerID_method:call(PlayerManager);
            return;
        end
    end
    this.MasterPlayerIndex = nil;
end

function this.checkGameStatus(checkType)
    local SnowGameManager = this.SDK.get_managed_singleton("snow.SnowGameManager");
    if SnowGameManager == nil then
        return nil;
    end
    return checkType == get_CurrentStatus_method:call(SnowGameManager);
end

function this.checkQuestStatus(questManager, checkType)
    if questManager == nil then
        questManager = this.SDK.get_managed_singleton("snow.QuestManager");
        if questManager == nil then
            return nil;
        end
    end
    return checkStatus_method:call(questManager, checkType);
end

function this.ClearFade()
    local FadeManager = this.SDK.get_managed_singleton("snow.FadeManager");
    if FadeManager == nil then
        return;
    end

    set_FadeMode_method:call(FadeManager, FadeMode_FINISH);
    FadeManager:set_field("fadeOutInFlag", false);
end

function this.getQuestMapNo(questManager)
    if questManager == nil then
        questManager = this.SDK.get_managed_singleton("snow.QuestManager");
        if questManager == nil then
            return nil;
        end
    end

    return getMapNo_method:call(questManager);
end

function this.getCurrentPosition()
    local CameraManager = this.SDK.get_managed_singleton("snow.CameraManager");
    if CameraManager ~= nil then
        local Transform = GetTransform_method:call(CameraManager, GameObjectType_MasterPlayer);
        if Transform ~= nil then
            return get_Position_method:call(Transform);
        end
    end

    return nil;
end

function this.SKIP_ORIGINAL()
    return this.SDK.SKIP_ORIGINAL;
end

function this.Return_TRUE()
    return this.TRUE_POINTER;
end

function this.to_bool(value)
    return (this.SDK.to_int64(value) & 1) == 1;
end

function this.to_byte(value)
    return this.SDK.to_int64(value) & 0xFF;
end

function this.to_uint(value)
    return this.SDK.to_int64(value) & 0xFFFFFFFF;
end
--
return this;