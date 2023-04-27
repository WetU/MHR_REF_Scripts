local json = json;
local jsonAvailable = json ~= nil;
local json_load_file = jsonAvailable and json.load_file or nil;
local json_dump_file = jsonAvailable and json.dump_file or nil;

local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
local sdk_hook = sdk.hook;

local re = re;
local re_on_config_save = re.on_config_save;
local re_on_draw_ui = re.on_draw_ui;

local imgui = imgui;
local imgui_load_font = imgui.load_font;
local imgui_push_font = imgui.push_font;
local imgui_pop_font = imgui.pop_font;
local imgui_tree_node = imgui.tree_node;
local imgui_tree_pop = imgui.tree_pop;
local imgui_checkbox = imgui.checkbox;
local imgui_combo = imgui.combo;
local imgui_slider_int = imgui.slider_int;

local pairs = pairs;

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
    0
};
local Font = imgui_load_font("NotoSansKR-Bold.otf", 18, KOREAN_GLYPH_RANGES);
local Languages = {"en-US", "ko-KR"};

----------- Helper Functions ----------------
local function FindIndex(table, value)
    for i = 1, #table do
        if table[i] == value then
            return i;
        end
    end
    return nil;
end

------------- Config Management --------------
local config = {};

if json_load_file then
    local loadedConfig = json_load_file("AutoSupply.json");
    config = loadedConfig or {Enabled = true, EnableNotification = true, EnableCohoot = true, DefaultSet = 1, WeaponTypeConfig = {}, EquipLoadoutConfig = {}, CohootMaxStock = 5, Language = "ko-KR"};
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
    config.Language = "ko-KR";
end

local function save_config()
    if json_dump_file then
        json_dump_file("AutoSupply.json", config);
    end
end

re_on_config_save(save_config);

local ChatManager_type_def = sdk_find_type_definition("snow.gui.ChatManager");
local reqAddChatInfomation_method = ChatManager_type_def:get_method("reqAddChatInfomation(System.String, System.UInt32)");
local reqAddChatItemInfo_method = ChatManager_type_def:get_method("reqAddChatItemInfo(snow.data.ContentsIdSystem.ItemId, System.Int32, snow.gui.ChatManager.ItemMaxType, System.Boolean)");

local DataManager_type_def = sdk_find_type_definition("snow.data.DataManager");
local getVillagePoint_method = DataManager_type_def:get_method("getVillagePoint");
local getItemMySet_method = DataManager_type_def:get_method("get_ItemMySet");
local trySellGameItem_method = DataManager_type_def:get_method("trySellGameItem(snow.data.ItemInventoryData, System.UInt32)");

local VillagePoint_type_def = getVillagePoint_method:get_return_type();
local get_Point_method = VillagePoint_type_def:get_method("get_Point");
local subPoint_method = VillagePoint_type_def:get_method("subPoint");

local ItemMySet_type_def = getItemMySet_method:get_return_type();
local applyItemMySet_method = ItemMySet_type_def:get_method("applyItemMySet(System.Int32)");
local getData_method = ItemMySet_type_def:get_method("getData(System.Int32)");

local PlItemPouchMySetData_type_def = getData_method:get_return_type();
local PlItemPouchMySetData_get_Name_method = PlItemPouchMySetData_type_def:get_method("get_Name");
local isEnoughItem_method = PlItemPouchMySetData_type_def:get_method("isEnoughItem");
local get_PaletteSetIndex_method = PlItemPouchMySetData_type_def:get_method("get_PaletteSetIndex");

local GetValueOrDefault_method = get_PaletteSetIndex_method:get_return_type():get_method("GetValueOrDefault");

local EquipDataManager_type_def = sdk_find_type_definition("snow.data.EquipDataManager");
local applyEquipMySet_method = EquipDataManager_type_def:get_method("applyEquipMySet(snow.equip.PlEquipMySetData)");
local PlEquipMySetList_field = EquipDataManager_type_def:get_field("_PlEquipMySetList");

local PlEquipMySetList_get_Item_method = PlEquipMySetList_field:get_type():get_method("get_Item(System.Int32)");

local PlEquipMySetData_type_def = PlEquipMySetList_get_Item_method:get_return_type();
local get_Name_method = PlEquipMySetData_type_def:get_method("get_Name");
local get_IsUsing_method = PlEquipMySetData_type_def:get_method("get_IsUsing");
local isSamePlEquipPack_method = PlEquipMySetData_type_def:get_method("isSamePlEquipPack");
local getWeaponData_method = PlEquipMySetData_type_def:get_method("getWeaponData");

local get_PlWeaponType_method = getWeaponData_method:get_return_type():get_method("get_PlWeaponType");

local getCustomShortcutSystem_method = sdk_find_type_definition("snow.data.SystemDataManager"):get_method("getCustomShortcutSystem");

local CustomShortcutSystem_type_def = getCustomShortcutSystem_method:get_return_type();
local setUsingPaletteIndex_method = CustomShortcutSystem_type_def:get_method("setUsingPaletteIndex(snow.data.CustomShortcutSystem.SycleTypes, System.Int32)");
local getPaletteSetList_method = CustomShortcutSystem_type_def:get_method("getPaletteSetList(snow.data.CustomShortcutSystem.SycleTypes)");

local palletteSetData_get_Item_method = getPaletteSetList_method:get_return_type():get_method("get_Item(System.Int32)");

local palletteSetData_get_Name_method = palletteSetData_get_Item_method:get_return_type():get_method("get_Name");

local GuiCampFsmManager_start_method = sdk_find_type_definition("snow.gui.fsm.camp.GuiCampFsmManager"):get_method("start");

local VillageAreaManager_type_def = sdk_find_type_definition("snow.VillageAreaManager");
local get__CurrentAreaNo_method = VillageAreaManager_type_def:get_method("get__CurrentAreaNo");
local set__CurrentAreaNo_method = VillageAreaManager_type_def:get_method("set__CurrentAreaNo(snow.stage.StageDef.AreaNoType)");

local AreaNoType_type_def = get__CurrentAreaNo_method:get_return_type();
local KAMURA = AreaNoType_type_def:get_field("No02"):get_data(nil);
local ELGADO = AreaNoType_type_def:get_field("No06"):get_data(nil);

local owlNestManagerSingleton_type_def = sdk_find_type_definition("snow.progress.ProgressOwlNestManager");
local supply_method = owlNestManagerSingleton_type_def:get_method("supply");
local get_SaveData_method = owlNestManagerSingleton_type_def:get_method("get_SaveData");

local progressOwlNestSaveData_type_def = get_SaveData_method:get_return_type();
local kamuraStackCount_field = progressOwlNestSaveData_type_def:get_field("_StackCount");
local elgadoStackCount_field = progressOwlNestSaveData_type_def:get_field("_StackCount2");

local findMasterPlayer_method = sdk_find_type_definition("snow.player.PlayerManager"):get_method("findMasterPlayer");

local playerWeaponType_field = findMasterPlayer_method:get_return_type():get_field("_playerWeaponType");

local get_TradeFunc_method = sdk_find_type_definition("snow.facility.TradeCenterFacility"):get_method("get_TradeFunc");

local TradeFunc_type_def = get_TradeFunc_method:get_return_type();
local get_TradeOrderList_method = TradeFunc_type_def:get_method("get_TradeOrderList");
local getNegotiationData_method = TradeFunc_type_def:get_method("getNegotiationData")

local NegotiationData_type_def = getNegotiationData_method:get_return_type();
local get_Cost_method = NegotiationData_type_def:get_method("get_Cost");
local NegotiationData_get_Count_method = NegotiationData_type_def:get_method("get_Count");

local TradeOrder_type_def = sdk_find_type_definition("snow.facility.tradeCenter.TradeOrderData");
local initialize_method = TradeOrder_type_def:get_method("initialize");
local get_InventoryList_method = TradeOrder_type_def:get_method("get_InventoryList");
local get_NegotiationCount_method = TradeOrder_type_def:get_method("get_NegotiationCount");
local setNegotiationCount_method = TradeOrder_type_def:get_method("setNegotiationCount(System.UInt32)");
local get_NegotiationType_method = TradeOrder_type_def:get_method("get_NegotiationType");

local Inventory_type_def = sdk_find_type_definition("snow.data.ItemInventoryData");
local isEmpty_method = Inventory_type_def:get_method("isEmpty");
local get_ItemId_method = Inventory_type_def:get_method("get_ItemId");
local Inventory_get_Count_method = Inventory_type_def:get_method("get_Count");
local sendInventory_method = Inventory_type_def:get_method("sendInventory(snow.data.ItemInventoryData, snow.data.ItemInventoryData, System.UInt32)");

local SendInventoryResult_AllSended = sendInventory_method:get_return_type():get_field("AllSended"):get_data(nil);

local onVillageStart_method = sdk_find_type_definition("snow.wwise.WwiseChangeSpaceWatcher"):get_method("onVillageStart");
--
local function SendMessage(text)
    if config.EnableNotification then
        local ChatManager = sdk_get_managed_singleton("snow.gui.ChatManager");
        if ChatManager then
		    reqAddChatInfomation_method:call(ChatManager, text, 2289944406);
        end
	end
end

local function GetItemLoadout(loadoutIndex)
    local DataManager = sdk_get_managed_singleton("snow.data.DataManager");
    if DataManager then
        local ItemMySet = getItemMySet_method:call(DataManager);
        if ItemMySet then
            return getData_method:call(ItemMySet, loadoutIndex);
        end
    end
    return nil;
end

local function ApplyItemLoadout(loadoutIndex)
    local DataManager = sdk_get_managed_singleton("snow.data.DataManager");
    if DataManager then
        local ItemMySet = getItemMySet_method:call(DataManager);
        if ItemMySet then
            return applyItemMySet_method:call(ItemMySet, loadoutIndex);
        end
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
    local PlayerManager = sdk_get_managed_singleton("snow.player.PlayerManager");
    if PlayerManager then
        local MasterPlayer = findMasterPlayer_method:call(PlayerManager);
        if MasterPlayer then
            return playerWeaponType_field:get_data(MasterPlayer);
        end
    end
    return nil;
end

local function GetEquipmentLoadout(loadoutIndex)
    local EquipDataManager = sdk_get_managed_singleton("snow.data.EquipDataManager");
    if EquipDataManager then
        local PlEquipMySetList = PlEquipMySetList_field:get_data(EquipDataManager);
        if PlEquipMySetList then
            return PlEquipMySetList_get_Item_method:call(PlEquipMySetList, loadoutIndex);
        end
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
    local itemLoadoutIndex, matchedType, matchedName, loadoutMismatch = AutoChooseItemLoadout(loadoutIndex);
    local loadout = GetItemLoadout(itemLoadoutIndex);
    local itemLoadoutName = PlItemPouchMySetData_get_Name_method:call(loadout);
    local msg = "";
    if isEnoughItem_method:call(loadout) then
        ApplyItemLoadout(itemLoadoutIndex);
        msg = matchedType == "Loadout" and FromLoadout(matchedName, itemLoadoutName)
            or matchedType == "WeaponType" and FromWeaponType(matchedName, itemLoadoutName, loadoutMismatch)
            or FromDefault(itemLoadoutName, loadoutMismatch);

        local paletteIndex = get_PaletteSetIndex_method:call(loadout);
        if not paletteIndex then
            msg = msg .. "\n" .. PaletteNilError();
        else
            local SystemDataManager = sdk_get_managed_singleton("snow.data.SystemDataManager");
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

local function Supply()
    local ProgressOwlNestManager = sdk_get_managed_singleton("snow.progress.ProgressOwlNestManager");
    if ProgressOwlNestManager then
        local saveData = get_SaveData_method:call(ProgressOwlNestManager);
        if saveData then
            local kamuraStack = kamuraStackCount_field:get_data(saveData);
            local elgadoStack = elgadoStackCount_field:get_data(saveData);
            if kamuraStack >= config.CohootMaxStock and elgadoStack < config.CohootMaxStock then
                local VillageAreaManager = sdk_get_managed_singleton("snow.VillageAreaManager");
                if VillageAreaManager then
                    local savedAreaNo = get__CurrentAreaNo_method:call(VillageAreaManager);
                    if savedAreaNo ~= KAMURA then
                        set__CurrentAreaNo_method:call(VillageAreaManager, KAMURA);
                        supply_method:call(ProgressOwlNestManager);
                        set__CurrentAreaNo_method:call(VillageAreaManager, savedAreaNo);
                    else
                        supply_method:call(ProgressOwlNestManager);
                    end
                end
            elseif elgadoStack >= config.CohootMaxStock and kamuraStack < config.CohootMaxStock then
                local VillageAreaManager = sdk_get_managed_singleton("snow.VillageAreaManager");
                if VillageAreaManager then
                    local savedAreaNo = get__CurrentAreaNo_method:call(VillageAreaManager);
                    if savedAreaNo ~= ELGADO then
                        set__CurrentAreaNo_method:call(VillageAreaManager, ELGADO);
                        supply_method:call(ProgressOwlNestManager);
                        set__CurrentAreaNo_method:call(VillageAreaManager, savedAreaNo);
                    else
                        supply_method:call(ProgressOwlNestManager);
                    end
                end
            elseif kamuraStack >= config.CohootMaxStock and elgadoStack >= config.CohootMaxStock then
                local VillageAreaManager = sdk_get_managed_singleton("snow.VillageAreaManager");
                if VillageAreaManager then
                    local savedAreaNo = get__CurrentAreaNo_method:call(VillageAreaManager);
                    if savedAreaNo == KAMURA then
                        supply_method:call(ProgressOwlNestManager);
                        set__CurrentAreaNo_method:call(VillageAreaManager, ELGADO);
                    elseif savedAreaNo == ELGADO then
                        supply_method:call(ProgressOwlNestManager);
                        set__CurrentAreaNo_method:call(VillageAreaManager, KAMURA);
                    else
                        set__CurrentAreaNo_method:call(VillageAreaManager, KAMURA);
                        supply_method:call(ProgressOwlNestManager);
                        set__CurrentAreaNo_method:call(VillageAreaManager, ELGADO);
                    end
                    supply_method:call(ProgressOwlNestManager);
                    set__CurrentAreaNo_method:call(VillageAreaManager, savedAreaNo);
                end
            end
        end
    end
end

local function autoArgosy()
    local TradeCenterFacility = sdk_get_managed_singleton("snow.facility.TradeCenterFacility");
    if TradeCenterFacility then
        local tradeFunc = get_TradeFunc_method:call(TradeCenterFacility);
        if tradeFunc then
            local tradeOrderList = get_TradeOrderList_method:call(tradeFunc);
            if tradeOrderList then
                local DataManager = sdk_get_managed_singleton("snow.data.DataManager");
                if DataManager then
                    for i = 0, #tradeOrderList - 1, 1 do
                        local tradeOrder = tradeOrderList:get_element(i);
                        if tradeOrder then
                            local negotiationCount = get_NegotiationCount_method:call(tradeOrder);
                            local inventoryList = get_InventoryList_method:call(tradeOrder);

                            if negotiationCount == 1 then
                                local negotiationData = getNegotiationData_method:call(tradeFunc, get_NegotiationType_method:call(tradeOrder));
                                local negotiationCost = get_Cost_method:call(negotiationData);
                                if negotiationData and negotiationCost then
                                    local villagePoint = getVillagePoint_method:call(DataManager);
                                    if villagePoint and get_Point_method:call(villagePoint) >= negotiationCost then
                                        setNegotiationCount_method:call(tradeOrder, negotiationCount + NegotiationData_get_Count_method:call(negotiationData));
                                        subPoint_method:call(villagePoint, negotiationCost);
                                    end
                                end
                            end

                            for j = 0, #inventoryList - 1, 1 do
                                local inventory = inventoryList:get_element(j);
                                if inventory and not isEmpty_method:call(inventory) then
                                    local sendResult = sendInventory_method:call(inventory, inventory, 65536);
                                    if sendResult ~= SendInventoryResult_AllSended then
                                        trySellGameItem_method:call(DataManager, inventory, Inventory_get_Count_method:call(inventory));
                                    end
                                end
                            end

                            initialize_method:call(tradeOrder);
                        end
                    end
                end
            end
        end
    end
end

sdk_hook(applyEquipMySet_method, nil, function(retval)
    if config.Enabled then
        Restock(nil);
    end
    return retval;
end);

sdk_hook(GuiCampFsmManager_start_method, nil, function()
    if config.Enabled then
        Restock(nil);
    end
end);

sdk_hook(onVillageStart_method, nil, function()
    if config.Enabled then
        Restock(nil);
    end
    if config.EnableCohoot then
        Supply();
    end
    autoArgosy();
end);
----------------------------------------------
re_on_draw_ui(function()
    if Font then
        imgui_push_font(Font);
    end
    local changed = false;
    if imgui_tree_node("AutoSupply") then
        changed, config.Enabled = imgui_checkbox("Enabled", config.Enabled);
        changed, config.EnableNotification = imgui_checkbox("EnableNotification", config.EnableNotification);
        changed, config.EnableCohoot = imgui_checkbox("EnableCohootSupply", config.EnableCohoot);

        local langIdx = FindIndex(Languages, config.Language);
        local langChanged, new_langIdx = imgui_combo("Language", langIdx, Languages);
        if langChanged then
            config.Language = Languages[new_langIdx];
            save_config();
        end

        changed, config.DefaultSet = imgui_slider_int("Default ItemSet", config.DefaultSet, 0, 39, GetItemLoadoutName(config.DefaultSet));

        if imgui_tree_node("WeaponType") then
            for i = 1, 14, 1 do
                local weaponType = i - 1;
                changed, config.WeaponTypeConfig[i] = imgui_slider_int(GetWeaponName(weaponType), config.WeaponTypeConfig[i], -1, 39, GetWeaponTypeItemLoadoutName(weaponType));
            end
            imgui_tree_pop();
        end

        if imgui_tree_node("Loadout") then
            for i = 1, 224, 1 do
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
        imgui_tree_pop();
    else
        if changed then
            save_config();
        end
    end
    if Font then
        imgui_pop_font();
    end
end);