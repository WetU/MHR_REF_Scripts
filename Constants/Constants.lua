local string = string;
local math = math;
local lua_func = {
    type = type,
    pairs = pairs,
    tostring = tostring,

    string_format = string.format,

    math_min = math.min,
    math_max = math.max
};

local sdk = sdk;
local sdk_func = {
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
};

local imgui = imgui;
local imgui_func = {
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
    spacing = imgui.spacing,
};

local Vector2f = Vector2f;
local Vector2f_func = {
    new = Vector2f.new
};

local Vector3f = Vector3f;
local Vector3f_func = {
    new = Vector3f.new
};

local ValueType = ValueType;
local ValueType_func = {
    new = ValueType.new
};

local re = re;
local re_func = {
    on_frame = re.on_frame
};

local this = {
    LUA = lua_func,
    SDK = sdk_func,
    IMGUI = imgui_func,
    VECTOR2f = Vector2f_func,
    VECTOR3f = Vector3f_func,
    VALUETYPE = ValueType_func,
    RE = re_func,
    MasterPlayerIndex = nil
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
    PlayerManager_type_def = this.SDK.find_type_definition("snow.player.PlayerManager")
};

this.isOnVillageStarted = false;
--
local get_CurrentStatus_method = this.SDK.find_type_definition("snow.SnowGameManager"):get_method("get_CurrentStatus");
local GameStatusType_type_def = get_CurrentStatus_method:get_return_type();
this.GameStatusType = {
    Village = GameStatusType_type_def:get_field("Village"):get_data(nil),
    Quest = GameStatusType_type_def:get_field("Quest"):get_data(nil)
};

local checkStatus_method = this.type_definitions.QuestManager_type_def:get_method("checkStatus(snow.QuestManager.Status)");
this.QuestStatus = {
    Success = this.SDK.find_type_definition("snow.QuestManager.Status"):get_field("Success"):get_data(nil)
};

local getMasterPlayerID_method = this.type_definitions.PlayerManager_type_def:get_method("getMasterPlayerID");

local set_FadeMode_method = this.SDK.find_type_definition("snow.FadeManager"):get_method("set_FadeMode(snow.FadeManager.MODE)");
local FadeMode_FINISH = this.SDK.find_type_definition("snow.FadeManager.MODE"):get_field("FINISH"):get_data(nil);
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
local function PreHook_changeMasterPlayerID(args)
    this.GetMasterPlayerId(this.SDK.to_int64(args[3]));
end
this.SDK.hook(this.type_definitions.PlayerManager_type_def:get_method("changeMasterPlayerID(snow.player.PlayerIndex)"), PreHook_changeMasterPlayerID);
--
return this;