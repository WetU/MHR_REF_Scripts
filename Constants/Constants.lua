local string = string;
local table = table;
local math = math;
local lua_func = {
    type = type,
    pairs = pairs,
    ipairs = ipairs,
    pcall = pcall,
    tostring = tostring,
    assert = assert,
    setmetatable = setmetatable,

    string_find = string.find,
    string_format = string.format,
    string_rep = string.rep,

    table_insert = table.insert,
    table_concat = table.concat,

    math_floor = math.floor,
    math_random = math.random,
    math_cos = math.cos,
    math_sin = math.sin,
    math_min = math.min,
    math_max = math.max
};

local sdk = sdk;
local sdk_func = {
    is_managed_object = sdk.is_managed_object,
    find_type_definition = sdk.find_type_definition,
    get_managed_singleton = sdk.get_managed_singleton,
    to_managed_object = sdk.to_managed_object,
    hook = sdk.hook,
    hook_vtable = sdk.hook_vtable,
    to_ptr = sdk.to_ptr,
    to_int64 = sdk.to_int64,
    to_float = sdk.to_float,
    SKIP_ORIGINAL = sdk.PreHookResult.SKIP_ORIGINAL
};

local json = json;
local json_func = {
    load_file = json.load_file,
    dump_file = json.dump_file
};

local imgui = imgui;
local imgui_func = {
    load_font = imgui.load_font,
    push_font = imgui.push_font,
    pop_font = imgui.pop_font,
    tree_node = imgui.tree_node,
    tree_pop = imgui.tree_pop,
    checkbox = imgui.checkbox,
    combo = imgui.combo,
    slider_int = imgui.slider_int,
    slider_float = imgui.slider_float,
    button = imgui.button,
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
    same_line = imgui.same_line,
    set_next_window_pos = imgui.set_next_window_pos,
    set_next_window_size = imgui.set_next_window_size
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
    on_script_reset = re.on_script_reset,
    on_frame = re.on_frame,
    on_config_save = re.on_config_save,
    on_draw_ui = re.on_draw_ui
};

local this = {
    LUA = lua_func,
    SDK = sdk_func,
    JSON = json_func,
    IMGUI = imgui_func,
    VECTOR2f = Vector2f_func,
    VECTOR3f = Vector3f_func,
    VALUETYPE = ValueType_func,
    RE = re_func,
    MasterPlayerIndex = nil,
    type_definitions = {},
    QuestStatus = {}
};

this.TRUE_POINTER = this.SDK.to_ptr(1);
this.FALSE_POINTER = this.SDK.to_ptr(0);
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
this.type_definitions.CameraManager_type_def = this.SDK.find_type_definition("snow.CameraManager");
this.type_definitions.QuestManager_type_def = this.SDK.find_type_definition("snow.QuestManager");
this.type_definitions.DataManager_type_def = this.SDK.find_type_definition("snow.data.DataManager");
this.type_definitions.EquipDataManager_type_def = this.SDK.find_type_definition("snow.data.EquipDataManager");
this.type_definitions.GuiManager_type_def = this.SDK.find_type_definition("snow.gui.GuiManager");
this.type_definitions.StmGuiInput_type_def = this.SDK.find_type_definition("snow.gui.StmGuiInput");
this.type_definitions.PlayerManager_type_def = this.SDK.find_type_definition("snow.player.PlayerManager");

local checkStatus_method = this.type_definitions.QuestManager_type_def:get_method("checkStatus(snow.QuestManager.Status)"); -- retval
local getMasterPlayerID_method = this.type_definitions.PlayerManager_type_def:get_method("getMasterPlayerID"); -- retval
local set_FadeMode_method = this.SDK.find_type_definition("snow.FadeManager"):get_method("set_FadeMode(snow.FadeManager.MODE)");
local FadeMode_FINISH = this.SDK.find_type_definition("snow.FadeManager.MODE"):get_field("FINISH"):get_data(nil);

local QuestStatus_type_def = this.SDK.find_type_definition("snow.QuestManager.Status");
this.QuestStatus.None = QuestStatus_type_def:get_field("None"):get_data(nil);
this.QuestStatus.Success = QuestStatus_type_def:get_field("Success"):get_data(nil);

function this.GetMasterPlayerId(idx)
    this.MasterPlayerIndex = idx ~= nil and idx or getMasterPlayerID_method:call(this.SDK.get_managed_singleton("snow.player.PlayerManager"));
end

function this.checkQuestStatus(questManager, checkType)
    if not questManager then
        questManager = this.SDK.get_managed_singleton("snow.QuestManager");
    end
    return checkStatus_method:call(questManager, checkType);
end

function this.FindIndex(table, value)
    for i = 1, #table, 1 do
        if table[i] == value then
            return i;
        end
    end
    return nil;
end

function this.ClearFade()
    local FadeManager = this.SDK.get_managed_singleton("snow.FadeManager");
    if FadeManager then
        set_FadeMode_method:call(FadeManager, FadeMode_FINISH);
    end
end

this.SDK.hook(this.type_definitions.PlayerManager_type_def:get_method("changeMasterPlayerID(snow.player.PlayerIndex)"), function(args)
    this.GetMasterPlayerId(this.SDK.to_int64(args[3]) & 0xFF);
end);

return this;