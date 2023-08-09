local Constants = _G.require("Constants.Constants");

local string_format = Constants.lua.string_format;

local find_type_definition = Constants.sdk.find_type_definition;
local get_managed_singleton = Constants.sdk.get_managed_singleton;
--
local DefaultSet = 0;
--
local findMasterPlayer_method = Constants.type_definitions.PlayerManager_type_def:get_method("findMasterPlayer");
local playerWeaponType_field = findMasterPlayer_method:get_return_type():get_field("_playerWeaponType");

local get_ItemMySet_method = Constants.type_definitions.DataManager_type_def:get_method("get_ItemMySet"); -- static

local ItemMySet_type_def = get_ItemMySet_method:get_return_type();
local applyItemMySet_method = ItemMySet_type_def:get_method("applyItemMySet(System.Int32)");
local getData_method = ItemMySet_type_def:get_method("getData(System.Int32)");

local PlItemPouchMySetData_type_def = getData_method:get_return_type();
local PlItemPouchMySetData_get_Name_method = PlItemPouchMySetData_type_def:get_method("get_Name");
local isEnoughItem_method = PlItemPouchMySetData_type_def:get_method("isEnoughItem");
local get_PaletteSetIndex_method = PlItemPouchMySetData_type_def:get_method("get_PaletteSetIndex");

local PalleteSetIndex_type_def = get_PaletteSetIndex_method:get_return_type();
local get_HasValue_method = PalleteSetIndex_type_def:get_method("get_HasValue");
local get_Value_method = PalleteSetIndex_type_def:get_method("get_Value");

local PlEquipMySetList_field = Constants.type_definitions.EquipDataManager_type_def:get_field("_PlEquipMySetList");

local PlEquipMySetData_type_def = find_type_definition("snow.equip.PlEquipMySetData");
local get_Name_method = PlEquipMySetData_type_def:get_method("get_Name");
local isSamePlEquipPack_method = PlEquipMySetData_type_def:get_method("isSamePlEquipPack");

local getCustomShortcutSystem_method = find_type_definition("snow.data.SystemDataManager"):get_method("getCustomShortcutSystem"); -- static

local CustomShortcutSystem_type_def = getCustomShortcutSystem_method:get_return_type();
local setUsingPaletteIndex_method = CustomShortcutSystem_type_def:get_method("setUsingPaletteIndex(snow.data.CustomShortcutSystem.SycleTypes, System.Int32)");
local getPaletteSetList_method = CustomShortcutSystem_type_def:get_method("getPaletteSetList(snow.data.CustomShortcutSystem.SycleTypes)");

local PaletteSetList_get_Item_method = getPaletteSetList_method:get_return_type():get_method("get_Item(System.Int32)");

local PaletteSetData_get_Name_method = PaletteSetList_get_Item_method:get_return_type():get_method("get_Name");

local SycleTypes_Quest = find_type_definition("snow.data.CustomShortcutSystem.SycleTypes"):get_field("Quest"):get_data(nil);
--
local LocalizedStrings = {
    WeaponNames = {
        "대검",
        "슬래시액스",
        "태도",
        "라이트보우건",
        "헤비보우건",
        "해머",
        "건랜스",
        "랜스",
        "한손검",
        "쌍검",
        "수렵피리",
        "차지액스",
        "조충곤",
        "활"
    },

    FromLoadout = "장비 프리셋 [<COL YEL>%s</COL>]의 아이템 프리셋 [<COL YEL>%s</COL>] 적용",
    MismatchLoadout = "현재 장비와 일치하는 프리셋이 없습니다.\n",
    FromWeaponType = "무기 유형 [<COL YEL>%s</COL>]의 아이템 프리셋 [<COL YEL>%s</COL>] 적용",
    MismatchWeaponType = "현재 장비와 일치하는 프리셋이 없습니다\n무기 유형 [<COL YEL>%s</COL>]의 설정이 없습니다.\n",
    FromDefault = "기본 아이템 프리셋 [<COL YEL>%s</COL>] 적용",
    OutOfStock = "아이템 프리셋 [<COL YEL>%s</COL>]의 <COL RED>물품이 부족</COL>하여 적용이 취소되었습니다.",

    PaletteNilError = "<COL RED>오류</COL>：팔레트 미설정",
    PaletteApplied = "팔레트 [<COL YEL>%s</COL>] 적용",
    PaletteListEmpty = "팔레트 설정이 비어있습니다",

    WeaponTypeNilError = "<ERROR>:GetWeaponName failed"
};

local MATCH_TYPE = {
    1, -- Loadout
    2  -- WeaponType
};
--
local lastHitLoadoutIndex = nil;

local function GetCurrentWeaponType()
    return playerWeaponType_field:get_data(findMasterPlayer_method:call(get_managed_singleton("snow.player.PlayerManager")));
end

local function GetEquipmentLoadout(equipDataManager, loadoutIndex)
    local PlEquipMySetList = PlEquipMySetList_field:get_data(equipDataManager);
    return PlEquipMySetList:get_element(loadoutIndex);
end

local function GetEquipmentLoadoutName(equipDataManager, loadoutIndex)
    return get_Name_method:call(GetEquipmentLoadout(equipDataManager, loadoutIndex));
end

local function EquipmentLoadoutIsEquipped(equipDataManager, loadoutIndex)
    return isSamePlEquipPack_method:call(GetEquipmentLoadout(equipDataManager, loadoutIndex));
end

local function GetWeaponName(weaponType)
    return weaponType == nil and LocalizedStrings.WeaponTypeNilError or LocalizedStrings.WeaponNames[weaponType + 1];
end

local function FromWeaponType(equipName, itemName, mismatch)
    local msg = mismatch == true and LocalizedStrings.MismatchLoadout or "";
    return msg .. string_format(LocalizedStrings.FromWeaponType, equipName, itemName);
end

local function FromDefault(itemName, mismatch)
    local msg = mismatch == true and string_format(LocalizedStrings.MismatchWeaponType, GetWeaponName(GetCurrentWeaponType())) or "";
    return msg .. string_format(LocalizedStrings.FromDefault, itemName);
end

local function AutoChooseItemLoadout(equipDataManager, expectedLoadoutIndex)
    if expectedLoadoutIndex ~= nil then
        lastHitLoadoutIndex = expectedLoadoutIndex;
        return MATCH_TYPE[1], GetEquipmentLoadoutName(equipDataManager, expectedLoadoutIndex), nil;
    else
		if lastHitLoadoutIndex ~= nil and EquipmentLoadoutIsEquipped(equipDataManager, lastHitLoadoutIndex) == true then
            return MATCH_TYPE[1], GetEquipmentLoadoutName(equipDataManager, lastHitLoadoutIndex), nil;
        end

        for i = 0, 223, 1 do
            if EquipmentLoadoutIsEquipped(equipDataManager, i) == true then
                lastHitLoadoutIndex = i;
                return MATCH_TYPE[1], GetEquipmentLoadoutName(equipDataManager, i), nil;
            end
        end
    end

    return MATCH_TYPE[2], GetWeaponName(GetCurrentWeaponType()), true;
end
--
local this = {
    Restock = function(equipDataManager, loadoutIndex)
        local ItemMySet = get_ItemMySet_method:call(nil);
        local loadout = getData_method:call(ItemMySet, DefaultSet);

        if loadout ~= nil then
            local itemLoadoutName = PlItemPouchMySetData_get_Name_method:call(loadout);
            local msg = string_format(LocalizedStrings.OutOfStock, itemLoadoutName);

            if isEnoughItem_method:call(loadout) == true then
                local matchedType, matchedName, loadoutMismatch = AutoChooseItemLoadout(equipDataManager, loadoutIndex);
                applyItemMySet_method:call(ItemMySet, DefaultSet);
                msg = matchedType == MATCH_TYPE[1] and string_format(LocalizedStrings.FromLoadout, matchedName, itemLoadoutName)
                    or matchedType == MATCH_TYPE[2] and FromWeaponType(matchedName, itemLoadoutName, loadoutMismatch)
                    or FromDefault(itemLoadoutName, loadoutMismatch);

                local paletteIndex = get_PaletteSetIndex_method:call(loadout);

                if paletteIndex == nil then
                    msg = msg .. "\n" .. LocalizedStrings.PaletteNilError;
                elseif get_HasValue_method:call(paletteIndex) == true then
                    local radialSetIndex = get_Value_method:call(paletteIndex);
                    local ShortcutManager = getCustomShortcutSystem_method:call(nil);
                    local paletteList = getPaletteSetList_method:call(ShortcutManager, SycleTypes_Quest);
                    msg = paletteList == nil and msg .. "\n" .. LocalizedStrings.PaletteListEmpty
                        or msg .. "\n" .. string_format(LocalizedStrings.PaletteApplied, PaletteSetData_get_Name_method:call(PaletteSetList_get_Item_method:call(paletteList, radialSetIndex)));
                    setUsingPaletteIndex_method:call(ShortcutManager, SycleTypes_Quest, radialSetIndex);
                end
            end

            return msg;
        end
    end
};
--
return this;