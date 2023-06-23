local require = require;
local Constants = require("Constants.Constants");
local config = require("AutoSupply.config");
if not Constants or not config then
    return;
end
--
local this = {};
--
local findMasterPlayer_method = Constants.type_definitions.PlayerManager_type_def:get_method("findMasterPlayer"); -- retval
local playerWeaponType_field = findMasterPlayer_method:get_return_type():get_field("_playerWeaponType");

local getItemMySet_method = Constants.type_definitions.DataManager_type_def:get_method("get_ItemMySet"); -- static, retval

local ItemMySet_type_def = getItemMySet_method:get_return_type();
local applyItemMySet_method = ItemMySet_type_def:get_method("applyItemMySet(System.Int32)");
local getData_method = ItemMySet_type_def:get_method("getData(System.Int32)"); -- retval

local PlItemPouchMySetData_type_def = getData_method:get_return_type();
local PlItemPouchMySetData_get_Name_method = PlItemPouchMySetData_type_def:get_method("get_Name"); -- retval
local isEnoughItem_method = PlItemPouchMySetData_type_def:get_method("isEnoughItem"); -- retval
local get_PaletteSetIndex_method = PlItemPouchMySetData_type_def:get_method("get_PaletteSetIndex"); -- retval

local PalleteSetIndex_type_def = get_PaletteSetIndex_method:get_return_type();
local get_HasValue_method = PalleteSetIndex_type_def:get_method("get_HasValue"); -- retval
local get_Value_method = PalleteSetIndex_type_def:get_method("get_Value"); -- retval
local GetValueOrDefault_method = PalleteSetIndex_type_def:get_method("GetValueOrDefault"); -- retval

local PlEquipMySetList_field = Constants.type_definitions.EquipDataManager_type_def:get_field("_PlEquipMySetList");

local PlEquipMySetList_get_Item_method = PlEquipMySetList_field:get_type():get_method("get_Item(System.Int32)");  -- retval

local PlEquipMySetData_type_def = PlEquipMySetList_get_Item_method:get_return_type();
local get_Name_method = PlEquipMySetData_type_def:get_method("get_Name"); -- retval
local get_IsUsing_method = PlEquipMySetData_type_def:get_method("get_IsUsing"); -- retval
local isSamePlEquipPack_method = PlEquipMySetData_type_def:get_method("isSamePlEquipPack"); -- retval
local getWeaponData_method = PlEquipMySetData_type_def:get_method("getWeaponData"); -- retval

local get_PlWeaponType_method = getWeaponData_method:get_return_type():get_method("get_PlWeaponType"); -- retval

local getCustomShortcutSystem_method = Constants.SDK.find_type_definition("snow.data.SystemDataManager"):get_method("getCustomShortcutSystem"); -- static, retval

local CustomShortcutSystem_type_def = getCustomShortcutSystem_method:get_return_type();
local setUsingPaletteIndex_method = CustomShortcutSystem_type_def:get_method("setUsingPaletteIndex(snow.data.CustomShortcutSystem.SycleTypes, System.Int32)");
local getPaletteSetList_method = CustomShortcutSystem_type_def:get_method("getPaletteSetList(snow.data.CustomShortcutSystem.SycleTypes)"); -- retval

local palletteSetData_get_Item_method = getPaletteSetList_method:get_return_type():get_method("get_Item(System.Int32)"); -- retval

local palletteSetData_get_Name_method = palletteSetData_get_Item_method:get_return_type():get_method("get_Name"); -- retval

local SycleTypes_Quest = Constants.SDK.find_type_definition("snow.data.CustomShortcutSystem.SycleTypes"):get_field("Quest"):get_data(nil);
----------- Equipment Loadout Managementt ----
local function ApplyItemLoadout(loadoutIndex)
    local ItemMySet = getItemMySet_method:call(nil);
    if ItemMySet then
        return applyItemMySet_method:call(ItemMySet, loadoutIndex);
    end
    return nil;
end

function this.GetItemLoadoutName(loadoutIndex)
	local ItemLoadout = getData_method:call(getItemMySet_method:call(nil), loadoutIndex);
	if ItemLoadout then
		return PlItemPouchMySetData_get_Name_method:call(ItemLoadout);
	end
    return nil;
end

local function GetCurrentWeaponType()
    local PlayerManager = Constants.SDK.get_managed_singleton("snow.player.PlayerManager");
    if PlayerManager then
        local MasterPlayer = findMasterPlayer_method:call(PlayerManager);
        if MasterPlayer then
            return playerWeaponType_field:get_data(MasterPlayer);
        end
    end
    return nil;
end

local function GetEquipmentLoadout(equipDataManager, loadoutIndex)
    if not equipDataManager then
        equipDataManager = Constants.SDK.get_managed_singleton("snow.data.EquipDataManager");
    end
    local PlEquipMySetList = PlEquipMySetList_field:get_data(equipDataManager);
    if PlEquipMySetList then
        return PlEquipMySetList_get_Item_method:call(PlEquipMySetList, loadoutIndex);
    end
    return nil;
end

local function GetEquipmentLoadoutWeaponType(loadoutIndex)
	local EquipmentLoadout = GetEquipmentLoadout(nil, loadoutIndex);
	if EquipmentLoadout then
		local WeaponData = getWeaponData_method:call(EquipmentLoadout);
		if WeaponData then
			return get_PlWeaponType_method:call(WeaponData);
		end
	end
    return nil;
end

function this.GetEquipmentLoadoutName(equipDataManager, loadoutIndex)
	local EquipmentLoadout = GetEquipmentLoadout(equipDataManager, loadoutIndex);
	if EquipmentLoadout then
		return get_Name_method:call(EquipmentLoadout);
	end
    return nil;
end

function this.EquipmentLoadoutIsNotEmpty(loadoutIndex)
	local EquipmentLoadout = GetEquipmentLoadout(nil, loadoutIndex);
	if EquipmentLoadout then
		return get_IsUsing_method:call(EquipmentLoadout);
	end
    return nil;
end

function this.EquipmentLoadoutIsEquipped(equipDataManager, loadoutIndex)
	local EquipmentLoadout = GetEquipmentLoadout(equipDataManager, loadoutIndex);
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
    return LocalizedStrings[config.config.Language];
end

function this.GetWeaponName(weaponType)
    if weaponType == nil then
		return "<ERROR>:GetWeaponName failed";
	end
	return Localized().WeaponNames[weaponType];
end

local function UseDefaultItemSet()
    return Localized().UseDefaultItemSet;
end

local function WeaponTypeNotSetUseDefault(weaponName, itemName)
    return Constants.LUA.string_format(Localized().WeaponTypeNotSetUseDefault, weaponName, itemName);
end

local function UseWeaponTypeItemSet(weaponName, itemName)
    return Constants.LUA.string_format(Localized().UseWeaponTypeItemSet, weaponName, itemName);
end

local function FromLoadout(equipName, itemName)
    return Constants.LUA.string_format(Localized().FromLoadout, equipName, itemName);
end

local function FromWeaponType(equipName, itemName, mismatch)
    local msg = "";
    if mismatch then
        msg = Localized().MismatchLoadout;
    end
    return msg .. Constants.LUA.string_format(Localized().FromWeaponType, equipName, itemName);
end

local function FromDefault(itemName, mismatch)
    local msg = "";
    if mismatch then
        msg = Constants.LUA.string_format(Localized().MismatchWeaponType, this.GetWeaponName(GetCurrentWeaponType()));
    end
    return msg .. Constants.LUA.string_format(Localized().FromDefault, itemName);
end

local function OutOfStock(itemName)
    return Constants.LUA.string_format(Localized().OutOfStock, itemName);
end

local function PaletteNilError()
    return Localized().PaletteNilError;
end

local function PaletteApplied(paletteName)
    return Constants.LUA.string_format(Localized().PaletteApplied, paletteName);
end

local function PaletteListEmpty()
    return Localized().PaletteListEmpty;
end

local function EquipmentChanged()
    return "마지막 장비 프리셋 적용 이후 장비가 변경되었습니다.";
end

---------------      CORE      ----------------
function this.GetWeaponTypeItemLoadoutName(weaponType)
    local got = config.config.WeaponTypeConfig[weaponType + 1];
    if got == nil or got == -1 then
        return UseDefaultItemSet();
    end
    return this.GetItemLoadoutName(got);
end

function this.GetLoadoutItemLoadoutIndex(loadoutIndex)
    local got = config.config.EquipLoadoutConfig[loadoutIndex + 1];
    if got == nil or got == -1 then
        local weaponType = GetEquipmentLoadoutWeaponType(loadoutIndex);
        got = config.config.WeaponTypeConfig[weaponType + 1];
        if got == nil or got == -1 then
            return WeaponTypeNotSetUseDefault(this.GetWeaponName(weaponType), this.GetItemLoadoutName(config.config.DefaultSet));
        end
        return UseWeaponTypeItemSet(this.GetWeaponName(weaponType), this.GetItemLoadoutName(got));
    end
    return this.GetItemLoadoutName(got);
end

local function AutoChooseItemLoadout(equipDataManager, expectedLoadoutIndex)
    local cacheHit = false;
    local loadoutMismatch = false;
    if expectedLoadoutIndex then
        cacheHit = true;
        lastHitLoadoutIndex = expectedLoadoutIndex;
        local got = config.config.EquipLoadoutConfig[expectedLoadoutIndex + 1];
        if got ~= nil and got ~= -1 then
            return got, "Loadout", this.GetEquipmentLoadoutName(equipDataManager, expectedLoadoutIndex);
        end
    else
		if lastHitLoadoutIndex ~= -1 then
            local cachedLoadoutIndex = lastHitLoadoutIndex;
            if this.EquipmentLoadoutIsEquipped(equipDataManager, cachedLoadoutIndex) then
                lastHitLoadoutIndex = cachedLoadoutIndex;
                cacheHit = true;
                local got = config.config.EquipLoadoutConfig[cachedLoadoutIndex + 1];
                if got ~= nil and got ~= -1 then
                    return got, "Loadout", this.GetEquipmentLoadoutName(equipDataManager, cachedLoadoutIndex);
                end
            end
        end
        if not cacheHit then
            local found = false;
            for i = 1, 224, 1 do
                local loadoutIndex = i - 1;
                if this.EquipmentLoadoutIsEquipped(equipDataManager, loadoutIndex) then
                    found = true;
                    expectedLoadoutIndex = loadoutIndex;
                    lastHitLoadoutIndex = loadoutIndex;
                    local got = config.config.EquipLoadoutConfig[i];
                    if got ~= nil and got ~= -1 then
                        return got, "Loadout", this.GetEquipmentLoadoutName(equipDataManager, loadoutIndex);
                    end
                    break;
                end
            end
            if not found then
                loadoutMismatch = true;
            end
        end
    end
    local weaponType = expectedLoadoutIndex and GetEquipmentLoadoutWeaponType(expectedLoadoutIndex) or GetCurrentWeaponType();
    local got = config.config.WeaponTypeConfig[weaponType + 1];
    if got ~= nil and got ~= -1 then
        return got, "WeaponType", this.GetWeaponName(weaponType), loadoutMismatch;
    end
    return config.config.DefaultSet, "Default", "", loadoutMismatch;
end

------------------------
function this.Restock(equipDataManager, loadoutIndex)
    local itemLoadoutIndex, matchedType, matchedName, loadoutMismatch = AutoChooseItemLoadout(equipDataManager, loadoutIndex);
    local loadout = getData_method:call(getItemMySet_method:call(nil), itemLoadoutIndex);
    local itemLoadoutName = PlItemPouchMySetData_get_Name_method:call(loadout);
    local msg = "";
    if isEnoughItem_method:call(loadout) then
        ApplyItemLoadout(itemLoadoutIndex);
        msg = matchedType == "Loadout" and FromLoadout(matchedName, itemLoadoutName)
            or matchedType == "WeaponType" and FromWeaponType(matchedName, itemLoadoutName, loadoutMismatch)
            or FromDefault(itemLoadoutName, loadoutMismatch);

        local paletteIndex = get_PaletteSetIndex_method:call(loadout);
        if paletteIndex == nil then
            msg = msg .. "\n" .. PaletteNilError();
        else
            local radialSetIndex = get_HasValue_method:call(paletteIndex) and get_Value_method:call(paletteIndex) or GetValueOrDefault_method:call(paletteIndex);
            if radialSetIndex ~= nil then
                local ShortcutManager = getCustomShortcutSystem_method:call(nil);
                if ShortcutManager then
                    local paletteList = getPaletteSetList_method:call(ShortcutManager, SycleTypes_Quest);
                    if paletteList then
                        local palette = palletteSetData_get_Item_method:call(paletteList, radialSetIndex);
                        if palette ~= nil then
                            msg = msg .. "\n" .. PaletteApplied(palletteSetData_get_Name_method:call(palette));
                        end
                    else
                        msg = msg .. "\n" .. PaletteListEmpty();
                    end
                    setUsingPaletteIndex_method:call(ShortcutManager, SycleTypes_Quest, radialSetIndex);
                end
            end
        end
    else
        msg = OutOfStock(itemLoadoutName);
    end
    return msg;
end

return this;