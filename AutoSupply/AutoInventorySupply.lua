local Constants = require("Constants.Constants");
if Constants == nil then
    return;
end
--
local DefaultSet = 0
--
local this = {};
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

local PlEquipMySetList_get_Item_method = PlEquipMySetList_field:get_type():get_method("get_Item(System.Int32)");

local PlEquipMySetData_type_def = PlEquipMySetList_get_Item_method:get_return_type();
local get_Name_method = PlEquipMySetData_type_def:get_method("get_Name");
local isSamePlEquipPack_method = PlEquipMySetData_type_def:get_method("isSamePlEquipPack");

local getCustomShortcutSystem_method = Constants.SDK.find_type_definition("snow.data.SystemDataManager"):get_method("getCustomShortcutSystem"); -- static

local CustomShortcutSystem_type_def = getCustomShortcutSystem_method:get_return_type();
local setUsingPaletteIndex_method = CustomShortcutSystem_type_def:get_method("setUsingPaletteIndex(snow.data.CustomShortcutSystem.SycleTypes, System.Int32)");
local getPaletteSetList_method = CustomShortcutSystem_type_def:get_method("getPaletteSetList(snow.data.CustomShortcutSystem.SycleTypes)");

local paletteSetData_get_Item_method = getPaletteSetList_method:get_return_type():get_method("get_Item(System.Int32)");

local paletteSetData_get_Name_method = paletteSetData_get_Item_method:get_return_type():get_method("get_Name");

local SycleTypes_Quest = Constants.SDK.find_type_definition("snow.data.CustomShortcutSystem.SycleTypes"):get_field("Quest"):get_data(nil);
----------- Equipment Loadout Managementt ----
local function GetCurrentWeaponType()
    local PlayerManager = Constants.SDK.get_managed_singleton("snow.player.PlayerManager");
    if PlayerManager ~= nil then
        local MasterPlayer = findMasterPlayer_method:call(PlayerManager);
        if MasterPlayer ~= nil then
            return playerWeaponType_field:get_data(MasterPlayer);
        end
    end

    return nil;
end

local function GetEquipmentLoadout(equipDataManager, loadoutIndex)
    if loadoutIndex ~= nil then
        if equipDataManager == nil then
            equipDataManager = Constants.SDK.get_managed_singleton("snow.data.EquipDataManager");
        end

        if equipDataManager ~= nil then
            local PlEquipMySetList = PlEquipMySetList_field:get_data(equipDataManager);
            if PlEquipMySetList ~= nil then
                return PlEquipMySetList_get_Item_method:call(PlEquipMySetList, loadoutIndex);
            end
        end
    end

    return nil;
end

local function GetEquipmentLoadoutName(equipDataManager, loadoutIndex)
    if loadoutIndex ~= nil then
        if equipDataManager == nil then
            equipDataManager = Constants.SDK.get_managed_singleton("snow.data.EquipDataManager");
        end

        if equipDataManager ~= nil then
            local EquipmentLoadout = GetEquipmentLoadout(equipDataManager, loadoutIndex);
            if EquipmentLoadout ~= nil then
                return get_Name_method:call(EquipmentLoadout);
            end
        end
    end

    return nil;
end

local function EquipmentLoadoutIsEquipped(equipDataManager, loadoutIndex)
    if loadoutIndex ~= nil then
        if equipDataManager == nil then
            equipDataManager = Constants.SDK.get_managed_singleton("snow.data.EquipDataManager");
        end

        if equipDataManager ~= nil then
            local EquipmentLoadout = GetEquipmentLoadout(equipDataManager, loadoutIndex);
            if EquipmentLoadout ~= nil then
                return isSamePlEquipPack_method:call(EquipmentLoadout);
            end
        end
    end

    return nil;
end

--------------- Temporary Data ----------------
local lastHitLoadoutIndex = -1;

---------------  Localization  ----------------
local LocalizedStrings = {
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
        [13] = "활"
    },

    FromLoadout = "장비 프리셋 [<COL YEL>%s</COL>]의 아이템 프리셋 [<COL YEL>%s</COL>] 적용",
    MismatchLoadout = "현재 장비와 일치하는 프리셋이 없습니다.\n",
    FromWeaponType = "무기 유형 [<COL YEL>%s</COL>]의 아이템 프리셋 [<COL YEL>%s</COL>] 적용",
    MismatchWeaponType = "현재 장비와 일치하는 프리셋이 없습니다\n무기 유형 [<COL YEL>%s</COL>]의 설정이 없습니다.\n",
    FromDefault = "기본 아이템 프리셋 [<COL YEL>%s</COL>] 적용",
    OutOfStock = "아이템 프리셋 [<COL YEL>%s</COL>]의 <COL RED>물품이 부족</COL>하여 적용이 취소되었습니다.",

    PaletteNilError = "<COL RED>오류</COL>：팔레트 미설정",
    PaletteApplied = "팔레트 [<COL YEL>%s</COL>] 적용",
    PaletteListEmpty = "팔레트 설정이 비어있습니다"
};

local function GetWeaponName(weaponType)
    return weaponType == nil and "<ERROR>:GetWeaponName failed" or LocalizedStrings.WeaponNames[weaponType];
end

local function FromWeaponType(equipName, itemName, mismatch)
    local msg = mismatch == true and LocalizedStrings.MismatchLoadout or "";
    return msg .. Constants.LUA.string_format(LocalizedStrings.FromWeaponType, equipName, itemName);
end

local function FromDefault(itemName, mismatch)
    local msg = mismatch == true and Constants.LUA.string_format(LocalizedStrings.MismatchWeaponType, GetWeaponName(GetCurrentWeaponType())) or "";
    return msg .. Constants.LUA.string_format(LocalizedStrings.FromDefault, itemName);
end

---------------      CORE      ----------------
local function AutoChooseItemLoadout(equipDataManager, expectedLoadoutIndex)
    local loadoutMismatch = false;
    if expectedLoadoutIndex ~= nil then
        lastHitLoadoutIndex = expectedLoadoutIndex;
        return DefaultSet, "Loadout", GetEquipmentLoadoutName(equipDataManager, expectedLoadoutIndex);
    else
		if lastHitLoadoutIndex ~= -1 and EquipmentLoadoutIsEquipped(equipDataManager, lastHitLoadoutIndex) == true then
            return DefaultSet, "Loadout", GetEquipmentLoadoutName(equipDataManager, lastHitLoadoutIndex);
        end

        for i = 0, 223, 1 do
            if EquipmentLoadoutIsEquipped(equipDataManager, i) == true then
                expectedLoadoutIndex = i;
                lastHitLoadoutIndex = i;
                return DefaultSet, "Loadout", GetEquipmentLoadoutName(equipDataManager, i);
            end
        end

        loadoutMismatch = true;
    end

    return DefaultSet, "WeaponType", GetWeaponName(GetCurrentWeaponType()), loadoutMismatch;
end

------------------------
function this.Restock(equipDataManager, loadoutIndex)
    local itemLoadoutIndex, matchedType, matchedName, loadoutMismatch = AutoChooseItemLoadout(equipDataManager, loadoutIndex);
    local ItemMySet = get_ItemMySet_method:call(nil);
    local msg = "";
    if ItemMySet ~= nil and itemLoadoutIndex ~= nil then
        local loadout = getData_method:call(ItemMySet, itemLoadoutIndex);
        if loadout ~= nil then
            local itemLoadoutName = PlItemPouchMySetData_get_Name_method:call(loadout);
            if itemLoadoutName ~= nil then
                if isEnoughItem_method:call(loadout) == true then
                    applyItemMySet_method:call(ItemMySet, itemLoadoutIndex);
                    msg = matchedType == "Loadout" and Constants.LUA.string_format(LocalizedStrings.FromLoadout, matchedName, itemLoadoutName)
                        or matchedType == "WeaponType" and FromWeaponType(matchedName, itemLoadoutName, loadoutMismatch)
                        or FromDefault(itemLoadoutName, loadoutMismatch);
            
                    local paletteIndex = get_PaletteSetIndex_method:call(loadout);
                    if paletteIndex == nil then
                        msg = msg .. "\n" .. LocalizedStrings.PaletteNilError;
                    else
                        if get_HasValue_method:call(paletteIndex) == true then
                            local radialSetIndex = get_Value_method:call(paletteIndex);
                            if radialSetIndex ~= nil then
                                local ShortcutManager = getCustomShortcutSystem_method:call(nil);
                                if ShortcutManager ~= nil then
                                    local paletteList = getPaletteSetList_method:call(ShortcutManager, SycleTypes_Quest);
                                    if paletteList ~= nil then
                                        local palette = paletteSetData_get_Item_method:call(paletteList, radialSetIndex);
                                        if palette ~= nil then
                                            local paletteName = paletteSetData_get_Name_method:call(palette);
                                            if paletteName ~= nil then
                                                msg = msg .. "\n" .. Constants.LUA.string_format(LocalizedStrings.PaletteApplied, paletteName);
                                            end
                                        end
                                    else
                                        msg = msg .. "\n" .. LocalizedStrings.PaletteListEmpty;
                                    end
                                    setUsingPaletteIndex_method:call(ShortcutManager, SycleTypes_Quest, radialSetIndex);
                                end
                            end
                        end
                    end
                else
                    msg = Constants.LUA.string_format(LocalizedStrings.OutOfStock, itemLoadoutName);
                end
            end
        end
    end

    return msg;
end
--
return this;