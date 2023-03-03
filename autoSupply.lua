local json = json;
local json_load_file = nil;
local json_dump_file = nil;

local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
local sdk_hook = sdk.hook;

local re = re;
local re_on_config_save = re.on_config_save;
local re_on_draw_ui = re.on_draw_ui;

local imgui = imgui;
local imgui_load_font = imgui.load_font;
local imgui_tree_node = imgui.tree_node;
local imgui_checkbox = imgui.checkbox;
local imgui_tree_pop = imgui.tree_pop;
local imgui_push_font = imgui.push_font;
local imgui_combo = imgui.combo;
local imgui_slider_int = imgui.slider_int;
local imgui_text = imgui.text;
local imgui_pop_font = imgui.pop_font;

local ipairs = ipairs;

local string = string;
local string_format = string.format;
----------- Font ---------------------------
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
    0,
};
local Fonts = {["ko-KR"] = imgui_load_font("NotoSansKR-Bold.otf", 18, KOREAN_GLYPH_RANGES)};

----------- Helper Functions ----------------
local function FindIndex(table, value)
    for i = 1, #table do
        if table[i] == value then
            return i;
        end
    end
    return nil;
end

local CycleTypeMap = {};
for _, field in ipairs(sdk_find_type_definition("snow.data.CustomShortcutSystem.SycleTypes"):get_fields()) do
	if field:is_static() then
		local name = field:get_name();
		local raw_value = field:get_data(nil);
		CycleTypeMap[raw_value] = name;
	end
end

------------- Config Management --------------
local Languages = {"en-US", "ko-KR"};
local config = {};
local jsonAvailable = json ~= nil;
if jsonAvailable then
    json_load_file = json.load_file;
    json_dump_file = json.dump_file;
    local loadedConfig = json_load_file("AutoSupply.json");
    config = loadedConfig or {Enabled = true, EnableNotification = true, EnableCohoot = true, DefaultSet = 1, WeaponTypeConfig = {}, EquipLoadoutConfig = {}, CohootMaxStock = 5, Language = "en_US"};
end

if config.Enabled == nil then
    config.Enabled = true;
end
if config.EnableNotification == nil then
    config.EnableNotification = true;
end
if config.EnableCohoot == nil then
    config.EnableCohoot = true;
end
if config.DefaultSet == nil then
    config.DefaultSet = 1;
end
if config.WeaponTypeConfig == nil then
    config.WeaponTypeConfig = {};
end
for i = 1, 14, 1 do
    if config.WeaponTypeConfig[i] == nil then
        config.WeaponTypeConfig[i] = -1;
    end
end
if config.EquipLoadoutConfig == nil then
    config.EquipLoadoutConfig = {};
end
for i = 1, 112, 1 do
    if config.EquipLoadoutConfig[i] == nil then
        config.EquipLoadoutConfig[i] = -1;
    end
end
if config.CohootMaxStock == nil then
    config.CohootMaxStock = 5;
end
if config.Language == nil or FindIndex(Languages, config.Language) == nil then
    config.Language = "en-US";
end

local function save_config()
    if jsonAvailable then
        json_dump_file("AutoSupply.json", config);
    end
end

re_on_config_save(save_config);

local ChatManager = nil;
local DataManager = nil;
local PlayerManager = nil;
local EquipDataManager = nil;
local SystemDataManager = nil;
local ProgressOwlNestManager = nil;
local VillageAreaManager = nil;

local reqAddChatInfomation_method = sdk_find_type_definition("snow.gui.ChatManager"):get_method("reqAddChatInfomation(System.String, System.UInt32)");

local ItemMySet_type_def = sdk_find_type_definition("snow.data.ItemMySet");
local getData_method = ItemMySet_type_def:get_method("getData(System.Int32)");
local applyItemMySet_method = ItemMySet_type_def:get_method("applyItemMySet(System.Int32)");

local PlItemPouchMySetData_type_def = sdk_find_type_definition("snow.data.PlItemPouchMySetData");
local PlItemPouchMySetData_get_Name_method = PlItemPouchMySetData_type_def:get_method("get_Name");
local isEnoughItem_method = PlItemPouchMySetData_type_def:get_method("isEnoughItem");
local get_PaletteSetIndex_method = PlItemPouchMySetData_type_def:get_method("get_PaletteSetIndex");

local EquipDataManager_type_def = sdk_find_type_definition("snow.data.EquipDataManager");
local applyEquipMySet_method = EquipDataManager_type_def:get_method("applyEquipMySet(snow.equip.PlEquipMySetData)");
local PlEquipMySetList_field = EquipDataManager_type_def:get_field("_PlEquipMySetList");
local PlEquipMySetList_get_Item_method = PlEquipMySetList_field:get_type():get_method("get_Item(System.Int32)");

local PlEquipMySetData_type_def = sdk_find_type_definition("snow.equip.PlEquipMySetData");
local getWeaponData_method = PlEquipMySetData_type_def:get_method("getWeaponData");
local get_Name_method = PlEquipMySetData_type_def:get_method("get_Name");
local get_IsUsing_method = PlEquipMySetData_type_def:get_method("get_IsUsing");
local isSamePlEquipPack_method = PlEquipMySetData_type_def:get_method("isSamePlEquipPack");

local CustomShortcutSystem_type_def = sdk_find_type_definition("snow.data.CustomShortcutSystem");
local getPaletteSetList_method = CustomShortcutSystem_type_def:get_method("getPaletteSetList(snow.data.CustomShortcutSystem.SycleTypes)");
local setUsingPaletteIndex_method = CustomShortcutSystem_type_def:get_method("setUsingPaletteIndex(snow.data.CustomShortcutSystem.SycleTypes, System.Int32)");

local VillageAreaManager_type_def = sdk_find_type_definition("snow.VillageAreaManager");
local set__CurrentAreaNo_method = VillageAreaManager_type_def:get_method("set__CurrentAreaNo(snow.stage.StageDef.AreaNoType)");
local currentAreaNo_field = VillageAreaManager_type_def:get_field("<_CurrentAreaNo>k__BackingField");

local owlNestManagerSingleton_type_def = sdk_find_type_definition("snow.progress.ProgressOwlNestManager");
local get_SaveData_method = owlNestManagerSingleton_type_def:get_method("get_SaveData");
local supply_method = owlNestManagerSingleton_type_def:get_method("supply");

local progressOwlNestSaveData_type_def = sdk_find_type_definition("snow.progress.ProgressOwlNestSaveData");
local kamuraStackCount_field = progressOwlNestSaveData_type_def:get_field("_StackCount");
local elgadoStackCount_field = progressOwlNestSaveData_type_def:get_field("_StackCount2");

local AreaNoType_type_def = sdk_find_type_definition("snow.stage.StageDef.AreaNoType");
local KAMURA = AreaNoType_type_def:get_field("No02"):get_data(nil);
local ELGADO = AreaNoType_type_def:get_field("No06"):get_data(nil);

local getItemMySet_method = sdk_find_type_definition("snow.data.DataManager"):get_method("get_ItemMySet");
local findMasterPlayer_method = sdk_find_type_definition("snow.player.PlayerManager"):get_method("findMasterPlayer");
local playerWeaponType_field = sdk_find_type_definition("snow.player.PlayerBase"):get_field("_playerWeaponType");
local get_PlWeaponType_method = sdk_find_type_definition("snow.data.WeaponData"):get_method("get_PlWeaponType");
local GetValueOrDefault_method = sdk_find_type_definition("System.Nullable`1<System.Int32>"):get_method("GetValueOrDefault");
local getCustomShortcutSystem_method = sdk_find_type_definition("snow.data.SystemDataManager"):get_method("getCustomShortcutSystem");
local palletteSetData_get_Item_method = sdk_find_type_definition("System.Collections.Generic.List`1<snow.data.customShortcut.PaletteData>"):get_method("get_Item(System.Int32)");
local palletteSetData_get_Name_method = sdk_find_type_definition("snow.data.customShortcut.PaletteSetData"):get_method("get_Name");
local onVillageStart_method = sdk_find_type_definition("snow.wwise.WwiseChangeSpaceWatcher"):get_method("onVillageStart");

local function SendMessage(text)
    if config.EnableNotification then
        if not ChatManager or ChatManager:get_reference_count() <= 1 then
            ChatManager = sdk_get_managed_singleton("snow.gui.ChatManager");
        end
		reqAddChatInfomation_method:call(ChatManager, text, 2289944406);
	end
end

local function GetItemLoadout(loadoutIndex)
    if not DataManager or DataManager:get_reference_count() <= 1 then
        DataManager = sdk_get_managed_singleton("snow.data.DataManager");
    end

	local ItemMySet = getItemMySet_method:call(DataManager);
	if ItemMySet then
		return getData_method:call(ItemMySet, loadoutIndex);
	end
    return nil;
end

local function ApplyItemLoadout(loadoutIndex)
    if not DataManager or DataManager:get_reference_count() <= 1 then
        DataManager = sdk_get_managed_singleton("snow.data.DataManager");
    end

	local ItemMySet = getItemMySet_method:call(DataManager);
	if ItemMySet then
		return applyItemMySet_method:call(ItemMySet, loadoutIndex);
	end
    return nil;
end

local function GetItemLoadoutName(loadoutIndex)
	local ItemLoadout = GetItemLoadout(loadoutIndex);
	if ItemLoadout then
		return PlItemPouchMySetData_get_Name_method:call(ItemLoadout);
	end
    return nil;
end

----------- Equipment Loadout Managementt ----
local function GetCurrentWeaponType()
    if not PlayerManager or PlayerManager:get_reference_count() <= 1 then
        PlayerManager = sdk_get_managed_singleton("snow.player.PlayerManager");
    end

	local MasterPlayer = findMasterPlayer_method:call(PlayerManager);
	if MasterPlayer then
		return playerWeaponType_field:get_data(MasterPlayer);
	end
    return nil;
end

local function GetEquipmentLoadout(loadoutIndex)
    if not EquipDataManager or EquipDataManager:get_reference_count() <= 1 then
        EquipDataManager = sdk_get_managed_singleton("snow.data.EquipDataManager");
    end

	local PlEquipMySetList = PlEquipMySetList_field:get_data(EquipDataManager);
	if PlEquipMySetList then
		return PlEquipMySetList_get_Item_method:call(PlEquipMySetList, loadoutIndex);
	end
    return nil;
end

local function GetEquipmentLoadoutWeaponType(loadoutIndex)
	local EquipmentLoadout = GetEquipmentLoadout(loadoutIndex);
	if EquipmentLoadout then
		local WeaponData = getWeaponData_method:call(EquipmentLoadout);
		if WeaponData then
			return get_PlWeaponType_method:call(WeaponData);
		end
	end
    return nil;
end

local function GetEquipmentLoadoutName(loadoutIndex)
	local EquipmentLoadout = GetEquipmentLoadout(loadoutIndex);
	if EquipmentLoadout then
		return get_Name_method:call(EquipmentLoadout);
	end
    return nil;
end

local function EquipmentLoadoutIsNotEmpty(loadoutIndex)
	local EquipmentLoadout = GetEquipmentLoadout(loadoutIndex);
	if EquipmentLoadout then
		return get_IsUsing_method:call(EquipmentLoadout);
	end
    return nil;
end

local function EquipmentLoadoutIsEquipped(loadoutIndex)
	local EquipmentLoadout = GetEquipmentLoadout(loadoutIndex);
	if EquipmentLoadout then
		return isSamePlEquipPack_method:call(EquipmentLoadout);
	end
    return nil;
end

--------------- Temporary Data ----------------
local lastHitLoadoutIndex = -1;

---------------  Localization  ----------------
local LocalizedStrings = {
    ["en-US"] = {
        WeaponNames = {
            [0] = "Great Sword",
            [1] = "Swtich Axe",
            [2] = "Long Sword",
            [3] = "Light Bowgun",
            [4] = "Heavy Bowgun",
            [5] = "Hammer",
            [6] = "Gunlance",
            [7] = "Lance",
            [8] = "Sword & Shield",
            [9] = "Dual Blades",
            [10] = "Hunting Horn",
            [11] = "Charge Blade",
            [12] = "Insect Glaive",
            [13] = "Bow",
        },
        UseDefaultItemSet = "Use Default Setting",
        WeaponTypeNotSetUseDefault = "%s not set, use default setting %s",
        UseWeaponTypeItemSet = "Use %s setting: %s",

        FromLoadout = "Restock for equipment loadout [<COL YEL>%s</COL>] from item loadout [<COL YEL>%s</COL>]",
        MismatchLoadout = "Current equipment doesn't match any equipment loadout.\n",
        FromWeaponType = "Restock for weapon type [<COL YEL>%s</COL>] from item loadout [<COL YEL>%s</COL>].",
        MismatchWeaponType = "Current equipment doesn't match any equipment loadout, and weapon type [<COL YEL>%s</COL>] has no settings.\n",
        FromDefault = "Restock from default item loadout [<COL YEL>%s</COL>].",
        OutOfStock = "Restock [<COL YEL>%s</COL>] cancelled due to <COL RED>out of stock</COL>.",

        PaletteNilError = "<COL RED>ERROR</COL>: Radial set is nil.",
        PaletteApplied = "Radial set [<COL YEL>%s</COL>] applied.",
        PaletteListEmpty = "Radial set list is empty, skipped."
    },
    ["ko-KR"] = {
        WeaponNames = {
            [0] = "대검",
            [1] = "슬래시액스",
            [2] = "태도",
            [3] = "라이트보우건",
            [4] = "헤비보우건",
            [5] = "해머",
            [6] = "건랜스",
            [7] = "랜스",
            [8] = "한손검",
            [9] = "쌍검",
            [10] = "수렵피리",
            [11] = "차지액스",
            [12] = "조충곤",
            [13] = "활",
        },
        UseDefaultItemSet = "기본 설정 사용",
        WeaponTypeNotSetUseDefault = "%s의 설정이 없으므로,\n기본 설정 %s을(를) 사용합니다\n",
        UseWeaponTypeItemSet = "%s의 설정：%s",

        FromLoadout = "장비 프리셋 [<COL YEL>%s</COL>]의 아이템 프리셋 [<COL YEL>%s</COL>] 적용",
        MismatchLoadout = "현재 장비와 일치하는 프리셋이 없습니다.\n",
        FromWeaponType = "무기 유형 [<COL YEL>%s</COL>]의 아이템 프리셋 [<COL YEL>%s</COL>] 적용",
        MismatchWeaponType = "현재 장비와 일치하는 프리셋이 없습니다\n무기 유형 [<COL YEL>%s</COL>]의 설정이 없습니다.\n",
        FromDefault = "기본 아이템 프리셋 [<COL YEL>%s</COL>] 적용",
        OutOfStock = "아이템 프리셋 [<COL YEL>%s</COL>]의 <COL RED>물품이 부족</COL>하여 적용이 취소되었습니다.",

        PaletteNilError = "<COL RED>오류</COL>：팔레트 미설정",
        PaletteApplied = "팔레트 [<COL YEL>%s</COL>] 적용",
        PaletteListEmpty = "팔레트 설정이 비어있습니다"
    }
};

local function Localized()
    return LocalizedStrings[config.Language];
end

local function GetWeaponName(weaponType)
    if weaponType == nil then
		return "<ERROR>:GetWeaponName failed";
	end
	return Localized().WeaponNames[weaponType];
end

local function UseDefaultItemSet()
    return Localized().UseDefaultItemSet;
end

local function WeaponTypeNotSetUseDefault(weaponName, itemName)
    return string_format(Localized().WeaponTypeNotSetUseDefault, weaponName, itemName);
end

local function UseWeaponTypeItemSet(weaponName, itemName)
    return string_format(Localized().UseWeaponTypeItemSet, weaponName, itemName);
end

local function FromLoadout(equipName, itemName)
    return string_format(Localized().FromLoadout, equipName, itemName);
end

local function FromWeaponType(equipName, itemName, mismatch)
    local msg = "";
    if mismatch then
        msg = Localized().MismatchLoadout;
    end
    return msg .. string_format(Localized().FromWeaponType, equipName, itemName);
end

local function FromDefault(itemName, mismatch)
    local msg = "";
    if mismatch then
        msg = string_format(Localized().MismatchWeaponType, GetWeaponName(GetCurrentWeaponType()));
    end
    return msg .. string_format(Localized().FromDefault, itemName);
end

local function OutOfStock(itemName)
    return string_format(Localized().OutOfStock, itemName);
end

local function PaletteNilError()
    return Localized().PaletteNilError;
end

local function PaletteApplied(paletteName)
    return string_format(Localized().PaletteApplied, paletteName);
end

local function PaletteListEmpty()
    return Localized().PaletteListEmpty;
end

local function EquipmentChanged()
    return "마지막 장비 프리셋 적용 이후 장비가 변경되었습니다.";
end

---------------      CORE      ----------------
local function GetWeaponTypeItemLoadoutName(weaponType)
    local got = config.WeaponTypeConfig[weaponType + 1];
    if not got or got == -1 then
        return UseDefaultItemSet();
    end
    return GetItemLoadoutName(got);
end

local function GetLoadoutItemLoadoutIndex(loadoutIndex)
    local got = config.EquipLoadoutConfig[loadoutIndex + 1];
    if not got or got == -1 then
        local weaponType = GetEquipmentLoadoutWeaponType(loadoutIndex);
        got = config.WeaponTypeConfig[weaponType + 1];
        if not got or got == -1 then
            return WeaponTypeNotSetUseDefault(GetWeaponName(weaponType), GetItemLoadoutName(config.DefaultSet));
        end
        return UseWeaponTypeItemSet(GetWeaponName(weaponType), GetItemLoadoutName(got));
    end
    return GetItemLoadoutName(got);
end

local function AutoChooseItemLoadout(expectedLoadoutIndex)
    local cacheHit = false;
    local loadoutMismatch = false;
    if expectedLoadoutIndex then
        cacheHit = true;
        lastHitLoadoutIndex = expectedLoadoutIndex;
        local got = config.EquipLoadoutConfig[expectedLoadoutIndex + 1];
        if got and got ~= -1 then
            return got, "Loadout", GetEquipmentLoadoutName(expectedLoadoutIndex);
        end
    else
		if lastHitLoadoutIndex ~= -1 then
            local cachedLoadoutIndex = lastHitLoadoutIndex;
            if EquipmentLoadoutIsEquipped(cachedLoadoutIndex) then
                lastHitLoadoutIndex = cachedLoadoutIndex;
                cacheHit = true;
                local got = config.EquipLoadoutConfig[cachedLoadoutIndex + 1];
                if got and got ~= -1 then
                    return got, "Loadout", GetEquipmentLoadoutName(cachedLoadoutIndex);
                end
            end
        end
        if not cacheHit then
            local found = false;
            for i = 1, 112, 1 do
                local loadoutIndex = i - 1;
                if EquipmentLoadoutIsEquipped(loadoutIndex) then
                    found = true;
                    expectedLoadoutIndex = loadoutIndex;
                    lastHitLoadoutIndex = loadoutIndex;
                    local got = config.EquipLoadoutConfig[i];
                    if got and got ~= -1 then
                        return got, "Loadout", GetEquipmentLoadoutName(loadoutIndex);
                    end
                    break;
                end
            end
            if not found then
                loadoutMismatch = true;
            end
        end
    end
    local weaponType;
    if expectedLoadoutIndex then
        weaponType = GetEquipmentLoadoutWeaponType(expectedLoadoutIndex);
    else
        weaponType = GetCurrentWeaponType();
    end
    local got = config.WeaponTypeConfig[weaponType + 1];
    if got and got ~= -1 then
        return got, "WeaponType", GetWeaponName(weaponType), loadoutMismatch;
    end
    return config.DefaultSet, "Default", "", loadoutMismatch;
end

------------------------
local function Restock(loadoutIndex)
    if config.Enabled then
        local itemLoadoutIndex, matchedType, matchedName, loadoutMismatch = AutoChooseItemLoadout(loadoutIndex);
        local loadout = GetItemLoadout(itemLoadoutIndex);
        local itemLoadoutName = PlItemPouchMySetData_get_Name_method:call(loadout);
        local msg = "";
        if isEnoughItem_method:call(loadout) then
            ApplyItemLoadout(itemLoadoutIndex);
            if matchedType == "Loadout" then
                msg = FromLoadout(matchedName, itemLoadoutName);
            elseif matchedType == "WeaponType" then
                msg = FromWeaponType(matchedName, itemLoadoutName, loadoutMismatch);
            else
                msg = FromDefault(itemLoadoutName, loadoutMismatch);
            end

            local paletteIndex = get_PaletteSetIndex_method:call(loadout);
            if not paletteIndex then
                msg = msg .. "\n" .. PaletteNilError();
            else
                if not SystemDataManager or SystemDataManager:get_reference_count() <= 1 then
                    SystemDataManager = sdk_get_managed_singleton("snow.data.SystemDataManager");
                end
                if SystemDataManager then
                    local radialSetIndex = GetValueOrDefault_method:call(paletteIndex);
                    local ShortcutManager = getCustomShortcutSystem_method:call(SystemDataManager);
                    local paletteList = getPaletteSetList_method:call(ShortcutManager, 0);
                    if paletteList then
                        local palette = palletteSetData_get_Item_method:call(paletteList, radialSetIndex);
                        if palette then
                            msg = msg .. "\n" .. PaletteApplied(palletteSetData_get_Name_method:call(palette));
                        end
                    else
                        msg = msg .. "\n" .. PaletteListEmpty();
                    end
                    setUsingPaletteIndex_method:call(ShortcutManager, 0, radialSetIndex);
                end
            end
        else
            msg = OutOfStock(itemLoadoutName);
        end
        SendMessage(msg);
    end
end

local function Supply()
    if config.EnableCohoot then
        if not ProgressOwlNestManager or ProgressOwlNestManager:get_reference_count() <= 1 then
            ProgressOwlNestManager = sdk_get_managed_singleton("snow.progress.ProgressOwlNestManager");
        end
        if not VillageAreaManager or VillageAreaManager:get_reference_count() <= 1 then
            VillageAreaManager = sdk_get_managed_singleton("snow.VillageAreaManager");
        end
        if ProgressOwlNestManager and VillageAreaManager then
            local progressOwlNestSaveData = get_SaveData_method:call(ProgressOwlNestManager);
            if progressOwlNestSaveData then
                local kamuraStack = kamuraStackCount_field:get_data(progressOwlNestSaveData);
                local elgadoStack = elgadoStackCount_field:get_data(progressOwlNestSaveData);
                if kamuraStack >= config.CohootMaxStock then
                    local savedAreaNo = currentAreaNo_field:get_data(VillageAreaManager);
                    if savedAreaNo ~= KAMURA then
                        set__CurrentAreaNo_method:call(VillageAreaManager, KAMURA);
                        supply_method:call(ProgressOwlNestManager);
                        set__CurrentAreaNo_method:call(VillageAreaManager, savedAreaNo);
                    else
                        supply_method:call(ProgressOwlNestManager);
                    end
                end
                if elgadoStack >= config.CohootMaxStock then
                    local savedAreaNo = currentAreaNo_field:get_data(VillageAreaManager);
                    if savedAreaNo ~= ELGADO then
                        set__CurrentAreaNo_method:call(VillageAreaManager, ELGADO);
                        supply_method:call(ProgressOwlNestManager);
                        set__CurrentAreaNo_method:call(VillageAreaManager, savedAreaNo);
                    else
                        supply_method:call(ProgressOwlNestManager);
                    end
                end
            end
        end
    end
end

sdk_hook(applyEquipMySet_method, nil, function(retval)
	Restock();
	return retval;
end);

sdk_hook(onVillageStart_method, nil, function()
    Restock();
    Supply();
end);
----------------------------------------------
re_on_draw_ui(function()
    local font = Fonts[config.Language];
    if font then
        imgui_push_font(font);
    end
    if imgui_tree_node("AutoSupply") then
        local changed = false;
        changed, config.Enabled = imgui_checkbox("Enabled", config.Enabled);
        changed, config.EnableNotification = imgui_checkbox("EnableNotification", config.EnableNotification);
        changed, config.EnableCohoot = imgui_checkbox("EnableCohootSupply", config.EnableCohoot);

        local langIdx = FindIndex(Languages, config.Language);
        changed, langIdx = imgui_combo("Language", langIdx, Languages);
        config.Language = Languages[langIdx];

        changed, config.DefaultSet = imgui_slider_int("Default ItemSet", config.DefaultSet, 0, 39, GetItemLoadoutName(config.DefaultSet));

        if imgui_tree_node("WeaponType") then
            for i = 1, 14, 1 do
                local weaponType = i - 1;
                changed, config.WeaponTypeConfig[i] = imgui_slider_int(GetWeaponName(weaponType), config.WeaponTypeConfig[i], -1, 39, GetWeaponTypeItemLoadoutName(weaponType));
            end
            imgui_tree_pop();
        end

        if imgui_tree_node("Loadout") then
            for i = 1, 112, 1 do
                local loadoutIndex = i - 1;
                local name = GetEquipmentLoadoutName(loadoutIndex);
                if name and EquipmentLoadoutIsNotEmpty(loadoutIndex) then
                    local msg = "";
                    if EquipmentLoadoutIsEquipped(loadoutIndex) then 
                        msg = " (Current)";
                    end
                    changed, config.EquipLoadoutConfig[i] = imgui_slider_int(name .. msg, config.EquipLoadoutConfig[i], -1, 39, GetLoadoutItemLoadoutIndex(loadoutIndex));
                end
            end
            imgui_tree_pop();
        end

        if imgui_tree_node("Auto cohoot nest") then
            changed, config.CohootMaxStock = imgui_slider_int("Maximum stock", config.CohootMaxStock, 1, 5);
            imgui_tree_pop();
        end

        if changed then
            if not config.Enabled then
                ChatManager = nil;
                DataManager = nil;
                PlayerManager = nil;
                EquipDataManager = nil;
                SystemDataManager = nil;
            end
            if not config.EnableNotification then
                ChatManager = nil;
            end
            if not config.EnableCohoot then
                ProgressOwlNestManager = nil;
                VillageAreaManager = nil;
            end
            save_config();
        end
        imgui_tree_pop();
    end
    if font then
        imgui_pop_font();
    end
end);