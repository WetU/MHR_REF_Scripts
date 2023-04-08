local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
local sdk_to_managed_object = sdk.to_managed_object;
local sdk_to_int64 = sdk.to_int64;
local sdk_hook = sdk.hook;
local sdk_CALL_ORIGINAL = sdk.PreHookResult.CALL_ORIGINAL;

local re = re;
local re_on_frame = re.on_frame;

local imgui = imgui;
local imgui_load_font = imgui.load_font;
local imgui_push_font = imgui.push_font;
local imgui_pop_font = imgui.pop_font;
local imgui_begin_window = imgui.begin_window;
local imgui_end_window = imgui.end_window;
local imgui_text = imgui.text;

local math = math;
local math_ceil = math.ceil;

local pairs = pairs;
local tostring = tostring;
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
local getEquippingLvBuffcageData_method = sdk_find_type_definition("snow.data.EquipDataManager"):get_method("getEquippingLvBuffcageData");

local NormalLvBuffCageData_type_def = getEquippingLvBuffcageData_method:get_return_type();
local getStatusBuffLimit_method = NormalLvBuffCageData_type_def:get_method("getStatusBuffLimit(snow.data.NormalLvBuffCageData.BuffTypes)");
local getStatusBuffAddVal_method = NormalLvBuffCageData_type_def:get_method("getStatusBuffAddVal(snow.data.NormalLvBuffCageData.BuffTypes)");

local PlayerManager_type_def = sdk_find_type_definition("snow.player.PlayerManager");
local addLvBuffCnt_method = PlayerManager_type_def:get_method("addLvBuffCnt(System.Int32, snow.player.PlayerDefine.LvBuff)");

local QuestManager_type_def = sdk_find_type_definition("snow.QuestManager");
local QuestManager_update_method = QuestManager_type_def:get_method("update");
local getStatus_method = QuestManager_type_def:get_method("getStatus");
local Status_Play = getStatus_method:get_return_type():get_field("Play"):get_data(nil);

local LvBuff_type_def = sdk_find_type_definition("snow.player.PlayerDefine.LvBuff");
local LvBuff = {
    ["Atk"] = LvBuff_type_def:get_field("Attack"):get_data(nil),
    ["Def"] = LvBuff_type_def:get_field("Defence"):get_data(nil),
    ["Vital"] = LvBuff_type_def:get_field("Vital"):get_data(nil),
    ["Stamina"] = LvBuff_type_def:get_field("Stamina"):get_data(nil),
    ["Rainbow"] = LvBuff_type_def:get_field("Rainbow"):get_data(nil)
};

local NormalLvBuffCageData_BuffTypes_type_def = sdk_find_type_definition("snow.data.NormalLvBuffCageData.BuffTypes");
local BuffTypes = {
    ["Atk"] = NormalLvBuffCageData_BuffTypes_type_def:get_field("Atk"):get_data(nil),
    ["Def"] = NormalLvBuffCageData_BuffTypes_type_def:get_field("Def"):get_data(nil),
    ["Vital"] = NormalLvBuffCageData_BuffTypes_type_def:get_field("Vital"):get_data(nil),
    ["Stamina"] = NormalLvBuffCageData_BuffTypes_type_def:get_field("Stamina"):get_data(nil)
};
--
local DataCreated = false;

local StatusBuffLimits = nil;
local StatusBuffAddVal = nil;
local AcquiredCounts = nil;
local AcquiredValues = nil;

local QuestManager = nil;
sdk_hook(QuestManager_update_method, function(args)
    QuestManager = sdk_to_managed_object(args[2]);
    return sdk_CALL_ORIGINAL;
end, function()
    if QuestManager then
        if getStatus_method:call(QuestManager) == Status_Play then
            if not StatusBuffLimits or not StatusBuffAddVal then
                local EquipDataManager = sdk_get_managed_singleton("snow.data.EquipDataManager");
                if EquipDataManager then
                    local EquippingLvBuffcageData = getEquippingLvBuffcageData_method:call(EquipDataManager);
                    if EquippingLvBuffcageData then
                        StatusBuffLimits = {};
                        StatusBuffAddVal = {};
                        AcquiredCounts = {};
                        AcquiredValues = {};
                        for k, v in pairs(BuffTypes) do
                            StatusBuffLimits[k] = getStatusBuffLimit_method:call(EquippingLvBuffcageData, v);
                            StatusBuffAddVal[k] = getStatusBuffAddVal_method:call(EquippingLvBuffcageData, v);
                            AcquiredCounts[k] = 0;
                            AcquiredValues[k] = 0;
                        end
                        DataCreated = true;
                    end
                end
            end
        else
            DataCreated = false;
            StatusBuffLimits = nil;
            StatusBuffAddVal = nil;
            AcquiredCounts = nil;
            AcquiredValues = nil;
        end
        QuestManager = nil;
    end
end);

sdk_hook(addLvBuffCnt_method, function(args)
    local BuffType = sdk_to_int64(args[4]) & 0xFF;
    if BuffType == LvBuff.Rainbow then
        for k, v in pairs(StatusBuffLimits) do
            AcquiredCounts[k] = math_ceil(v / StatusBuffAddVal[k]);
            AcquiredValues[k] = v;
        end
    else
        local count = sdk_to_int64(args[3]) & 0xFFFFFFFF;
        if count and count > 0 then
            for k, v in pairs(LvBuff) do
                if BuffType == v then
                    AcquiredCounts[k] = AcquiredCounts[k] + count;
                    AcquiredValues[k] = AcquiredCounts[k] * StatusBuffAddVal[k];
                    return sdk_CALL_ORIGINAL;
                end
            end
        end
    end
    return sdk_CALL_ORIGINAL;
end);

re_on_frame(function()
    if DataCreated then
        imgui_push_font(font);
        if imgui_begin_window("인혼조", nil, 4096 + 64 + 512) then
            imgui_text("빨간 인혼조: " .. tostring(AcquiredCounts.Atk) .. "/" .. tostring(math_ceil(StatusBuffLimits.Atk / StatusBuffAddVal.Atk)) .. " (" .. tostring(AcquiredValues.Atk) .. "/" .. tostring(StatusBuffLimits.Atk) .. ")");
            imgui_text("주황 인혼조: " .. tostring(AcquiredCounts.Def) .. "/" .. tostring(math_ceil(StatusBuffLimits.Def / StatusBuffAddVal.Def)) .. " (" .. tostring(AcquiredValues.Def) .. "/" .. tostring(StatusBuffLimits.Def) .. ")");
            imgui_text("초록 인혼조: " .. tostring(AcquiredCounts.Vital) .. "/" .. tostring(math_ceil(StatusBuffLimits.Vital / StatusBuffAddVal.Vital)) .. " (" .. tostring(AcquiredValues.Vital) .. "/" .. tostring(StatusBuffLimits.Vital) .. ")");
            imgui_text("노란 인혼조: " .. tostring(AcquiredCounts.Stamina) .. "/" .. tostring(math_ceil(StatusBuffLimits.Stamina / StatusBuffAddVal.Stamina)) .. " (" .. tostring(AcquiredValues.Stamina) .. "/" .. tostring(StatusBuffLimits.Stamina) .. ")");
            imgui_pop_font();
            imgui_end_window();
        end
    end
end);