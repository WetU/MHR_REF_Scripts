local this = {
    isOnVillageStarted = false,
    TRUE_POINTER = sdk.to_ptr(true),
    FALSE_POINTER = sdk.to_ptr(false),
    Font = imgui.load_font("NotoSansKR-Bold.otf", 22, {
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
        Application_type_def = sdk.find_type_definition("via.Application"),
        CameraManager_type_def = sdk.find_type_definition("snow.CameraManager"),
        QuestManager_type_def = sdk.find_type_definition("snow.QuestManager"),
        VillageAreaManager_type_def = sdk.find_type_definition("snow.VillageAreaManager"),
        ItemId_type_def = sdk.find_type_definition("snow.data.ContentsIdSystem.ItemId"),
        DataManager_type_def = sdk.find_type_definition("snow.data.DataManager"),
        EquipDataManager_type_def = sdk.find_type_definition("snow.data.EquipDataManager"),
        GuiManager_type_def = sdk.find_type_definition("snow.gui.GuiManager"),
        StmGuiInput_type_def = sdk.find_type_definition("snow.gui.StmGuiInput"),
        PlayerManager_type_def = sdk.find_type_definition("snow.player.PlayerManager"),
        WwiseChangeSpaceWatcher_type_def = sdk.find_type_definition("snow.wwise.WwiseChangeSpaceWatcher")
    }
};
--
local getTrg_method = sdk.find_type_definition("snow.GameKeyboard.HardwareKeyboard"):get_method("getTrg(via.hid.KeyboardKey)"); -- static
local KeyboardKey_type_def = sdk.find_type_definition("via.hid.KeyboardKey");

this.Keys = {
    Home_key = KeyboardKey_type_def:get_field("Home"):get_data(nil),
    Q_key = KeyboardKey_type_def:get_field("Q"):get_data(nil),
    E_key = KeyboardKey_type_def:get_field("E"):get_data(nil)
};

function this.checkKeyTrg(key)
    return getTrg_method:call(nil, key);
end
--
local get_CurrentStatus_method = sdk.find_type_definition("snow.SnowGameManager"):get_method("get_CurrentStatus");
local GameStatusType_type_def = get_CurrentStatus_method:get_return_type();

this.GameStatusType = {
    Village = GameStatusType_type_def:get_field("Village"):get_data(nil),
    Quest = GameStatusType_type_def:get_field("Quest"):get_data(nil)
};

function this.checkGameStatus(checkType)
    local SnowGameManager = sdk.get_managed_singleton("snow.SnowGameManager");
    if SnowGameManager ~= nil then
        return checkType == get_CurrentStatus_method:call(SnowGameManager);
    end
    return nil;
end
--
local checkStatus_method = this.type_definitions.QuestManager_type_def:get_method("checkStatus(snow.QuestManager.Status)");

this.QuestStatus = {
    Success = sdk.find_type_definition("snow.QuestManager.Status"):get_field("Success"):get_data(nil)
};

function this.checkQuestStatus(questManager, checkType)
    if questManager == nil then
        questManager = sdk.get_managed_singleton("snow.QuestManager");
    end

    return checkStatus_method:call(questManager, checkType);
end
--
local set_FadeMode_method = sdk.find_type_definition("snow.FadeManager"):get_method("set_FadeMode(snow.FadeManager.MODE)");
local FadeMode_FINISH = sdk.find_type_definition("snow.FadeManager.MODE"):get_field("FINISH"):get_data(nil);

function this.ClearFade()
    local FadeManager = sdk.get_managed_singleton("snow.FadeManager");
    set_FadeMode_method:call(FadeManager, FadeMode_FINISH);
    FadeManager:set_field("fadeOutInFlag", false);
end
--
local getMapNo_method = this.type_definitions.QuestManager_type_def:get_method("getMapNo");
local MapNoType_type_def = getMapNo_method:get_return_type();

this.QuestMapList = {
    ["ShrineRuins"] = MapNoType_type_def:get_field("No01"):get_data(nil), -- 사원 폐허
    ["SandyPlains"] = MapNoType_type_def:get_field("No02"):get_data(nil), -- 모래 평원
    ["FloodedForest"] = MapNoType_type_def:get_field("No03"):get_data(nil), -- 수몰된 숲
    ["FrostIslands"] = MapNoType_type_def:get_field("No04"):get_data(nil), -- 한랭 군도
    ["LavaCaverns"] = MapNoType_type_def:get_field("No05"):get_data(nil), -- 용암 동굴
    ["Jungle"] = MapNoType_type_def:get_field("No31"):get_data(nil), -- 밀림
    ["Citadel"] = MapNoType_type_def:get_field("No32"):get_data(nil)  -- 요새 고원
};

function this.getQuestMapNo(questManager)
    if questManager == nil then
        questManager = sdk.get_managed_singleton("snow.QuestManager");
    end

    return getMapNo_method:call(questManager);
end
--
function this.SKIP_ORIGINAL()
    return sdk.PreHookResult.SKIP_ORIGINAL;
end

function this.RETURN_TRUE()
    return this.TRUE_POINTER;
end

function this.to_bool(value)
    return (sdk.to_int64(value) & 1) == 1;
end

function this.to_byte(value)
    return sdk.to_int64(value) & 0xFF;
end

function this.to_uint(value)
    return sdk.to_int64(value) & 0xFFFFFFFF;
end
--
return this;