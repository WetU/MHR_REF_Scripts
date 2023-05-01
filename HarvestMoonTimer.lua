local string = string;
local string_format = string.format;

local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_to_managed_object = sdk.to_managed_object;
local sdk_hook = sdk.hook;
local sdk_hook_vtable = sdk.hook_vtable;
local sdk_CALL_ORIGINAL = sdk.PreHookResult.CALL_ORIGINAL;

local re = re;
local re_on_frame = re.on_frame;

local imgui = imgui;
local imgui_load_font = imgui.load_font;
local imgui_push_font = imgui.push_font;
local imgui_pop_font = imgui.pop_font;
local imgui_text = imgui.text;
local imgui_begin_window = imgui.begin_window;
local imgui_end_window = imgui.end_window;

local LongSwordShell010_type_def = sdk_find_type_definition("snow.shell.LongSwordShell010");
local LongSwordShell010_start_method = LongSwordShell010_type_def:get_method("start");
local get_IsMaster_method = LongSwordShell010_type_def:get_method("get_IsMaster");
local lifeTimer_field = LongSwordShell010_type_def:get_field("_lifeTimer");
local CircleType_field = LongSwordShell010_type_def:get_field("_CircleType");

local CircleType_Inside = CircleType_field:get_type():get_field("Inside"):get_data(nil);
------
local KOREAN_GLYPH_RANGES = {
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
};
local font = imgui_load_font("NotoSansKR-Bold.otf", 22, KOREAN_GLYPH_RANGES);
------
local PrintStr = nil;

sdk_hook(LongSwordShell010_start_method, function(args)
    local obj = sdk_to_managed_object(args[2]);
    if obj ~= nil and get_IsMaster_method:call(obj) and CircleType_field:get_data(obj) == CircleType_Inside then
        local obj_type_def = obj:get_type_definition();
        sdk_hook_vtable(obj, obj_type_def:get_method("onDestroy"), nil, function()
            PrintStr = nil;
        end);

        sdk_hook_vtable(obj, obj_type_def:get_method("update"), nil, function()
            if obj ~= nil then
                PrintStr = string_format("원월 타이머: %.f초", lifeTimer_field:get_data(obj));
            end
        end);
    end
    return sdk_CALL_ORIGINAL;
end);

re_on_frame(function()
    if PrintStr then
        imgui_push_font(font);
        if imgui_begin_window("원월", nil, 4096 + 64 + 512) then
            imgui_text(PrintStr);
            imgui_pop_font();
            imgui_end_window();
        end
    end
end);