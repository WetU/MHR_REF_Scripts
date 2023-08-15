local Constants = _G.require("Constants.Constants");

local ipairs = Constants.lua.ipairs;
local string_format = Constants.lua.string_format;

local find_type_definition = Constants.sdk.find_type_definition;
--
local DefaultSet = 0;
--
local playerWeaponType_field = Constants.type_definitions.PlayerBase_type_def:get_field("_playerWeaponType");
--
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
--
local PlEquipMySetList_field = Constants.type_definitions.EquipDataManager_type_def:get_field("_PlEquipMySetList");

local PlEquipMySetData_type_def = find_type_definition("snow.equip.PlEquipMySetData");
local get_Name_method = PlEquipMySetData_type_def:get_method("get_Name");
local isSamePlEquipPack_method = PlEquipMySetData_type_def:get_method("isSamePlEquipPack");
--
local getCustomShortcutSystem_method = find_type_definition("snow.data.SystemDataManager"):get_method("getCustomShortcutSystem"); -- static

local CustomShortcutSystem_type_def = getCustomShortcutSystem_method:get_return_type();
local setUsingPaletteIndex_method = CustomShortcutSystem_type_def:get_method("setUsingPaletteIndex(snow.data.CustomShortcutSystem.SycleTypes, System.Int32)");
local getPaletteSetList_method = CustomShortcutSystem_type_def:get_method("getPaletteSetList(snow.data.CustomShortcutSystem.SycleTypes)");

local PaletteSetList_get_Item_method = getPaletteSetList_method:get_return_type():get_method("get_Item(System.Int32)");

local PaletteSetData_get_Name_method = PaletteSetList_get_Item_method:get_return_type():get_method("get_Name");
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

	WeaponTypeNilError = "<COL RED>오류</COL>：무기 유형 오류"
};
--
local lastHitLoadoutIndex = nil;

local function GetCurrentWeaponType()
	return playerWeaponType_field:get_data(Constants:get_MasterPlayerBase());
end

local function GetEquipmentLoadout(equipDataManager, loadoutIndex)
	return PlEquipMySetList_field:get_data(equipDataManager):get_element(loadoutIndex);
end

local function GetEquipmentLoadoutName(equipDataManager, loadoutIndex)
	return get_Name_method:call(GetEquipmentLoadout(equipDataManager, loadoutIndex));
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
		return 1, GetEquipmentLoadoutName(equipDataManager, expectedLoadoutIndex), nil;
	else
		if lastHitLoadoutIndex ~= nil then
			local expectedLoadout = GetEquipmentLoadout(equipDataManager, lastHitLoadoutIndex);
			if isSamePlEquipPack_method:call(expectedLoadout) then
				return 1, get_Name_method:call(expectedLoadout), nil;
			end
		end

		for i, PlEquipMySet in ipairs(PlEquipMySetList_field:get_data(equipDataManager):get_elements()) do
			if isSamePlEquipPack_method:call(PlEquipMySet) == true then
				lastHitLoadoutIndex = i - 1;
				return 1, get_Name_method:call(PlEquipMySet), nil;
			end
		end
	end

	return 2, GetWeaponName(GetCurrentWeaponType()), true;
end
--
local this = {
	Restock = function(loadoutIndex)
		local ItemMySet = get_ItemMySet_method:call(nil);
		local loadout = getData_method:call(ItemMySet, DefaultSet);

		if loadout ~= nil then
			local itemLoadoutName = PlItemPouchMySetData_get_Name_method:call(loadout);
			local msg = string_format(LocalizedStrings.OutOfStock, itemLoadoutName);

			if isEnoughItem_method:call(loadout) == true then
				local matchedType, matchedName, loadoutMismatch = AutoChooseItemLoadout(Constants:get_EquipDataManager(), loadoutIndex);
				applyItemMySet_method:call(ItemMySet, DefaultSet);
				msg = matchedType == 1 and string_format(LocalizedStrings.FromLoadout, matchedName, itemLoadoutName)
					or matchedType == 2 and FromWeaponType(matchedName, itemLoadoutName, loadoutMismatch)
					or FromDefault(itemLoadoutName, loadoutMismatch);

				local paletteIndex = get_PaletteSetIndex_method:call(loadout);

				if get_HasValue_method:call(paletteIndex) == true then
					local radialSetIndex = get_Value_method:call(paletteIndex);
					local ShortcutManager = getCustomShortcutSystem_method:call(nil);
					local paletteList = getPaletteSetList_method:call(ShortcutManager, DefaultSet);
					msg = paletteList == nil and msg .. "\n" .. LocalizedStrings.PaletteListEmpty
						or msg .. "\n" .. string_format(LocalizedStrings.PaletteApplied, PaletteSetData_get_Name_method:call(PaletteSetList_get_Item_method:call(paletteList, radialSetIndex)));
					setUsingPaletteIndex_method:call(ShortcutManager, DefaultSet, radialSetIndex);
				else
					msg = msg .. "\n" .. LocalizedStrings.PaletteNilError;
				end
			end

			return msg;
		end
	end
};
--
return this;