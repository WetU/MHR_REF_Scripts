local Constants = _G.require("Constants.Constants");
--
local string_format = Constants.lua.string_format;

local find_type_definition = Constants.sdk.find_type_definition;
--
local DefaultSet = 0;
--
local playerWeaponType_field = Constants.type_definitions.PlayerBase_type_def:get_field("_playerWeaponType");
--
local get_ItemMySet_method = find_type_definition("snow.data.DataManager"):get_method("get_ItemMySet"); -- static

local ItemMySet_type_def = get_ItemMySet_method:get_return_type();
local applyItemMySet_method = ItemMySet_type_def:get_method("applyItemMySet(System.Int32)");
local getData_method = ItemMySet_type_def:get_method("getData(System.Int32)");

local PlItemPouchMySetData_type_def = getData_method:get_return_type();
local PlItemPouchMySetData_get_Name_method = PlItemPouchMySetData_type_def:get_method("get_Name");
local isEnoughItem_method = PlItemPouchMySetData_type_def:get_method("isEnoughItem");
--
local get_PlEquipMySetList_method = Constants.type_definitions.EquipDataManager_type_def:get_method("get_PlEquipMySetList");

local PlEquipMySetData_type_def = find_type_definition("snow.equip.PlEquipMySetData");
local PlEquipMySetData_get_Name_method = PlEquipMySetData_type_def:get_method("get_Name");
local isSamePlEquipPack_method = PlEquipMySetData_type_def:get_method("isSamePlEquipPack");
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
	OutOfStock = "아이템 프리셋 [<COL YEL>%s</COL>]의 <COL RED>물품이 부족</COL>하여 적용이 취소되었습니다.",

	WeaponTypeNilError = "<COL RED>오류</COL>：무기 유형 오류"
};
--
local lastHitLoadoutIndex = nil;

local function GetWeaponName()
	local weaponType = playerWeaponType_field:get_data(Constants:get_MasterPlayerBase());
	return weaponType == nil and LocalizedStrings.WeaponTypeNilError or LocalizedStrings.WeaponNames[weaponType + 1];
end

local function FromWeaponType(equipName, itemName, mismatch)
	local msg = mismatch == true and LocalizedStrings.MismatchLoadout or "";
	return msg .. string_format(LocalizedStrings.FromWeaponType, equipName, itemName);
end

local function AutoChooseItemLoadout(equipDataManager, expectedLoadoutIndex)
	local PlEquipMySetList = get_PlEquipMySetList_method:call(equipDataManager);

	if expectedLoadoutIndex ~= nil then
		lastHitLoadoutIndex = expectedLoadoutIndex;
		return 1, PlEquipMySetData_get_Name_method:call(PlEquipMySetList:get_element(expectedLoadoutIndex)), nil;
	end

	if lastHitLoadoutIndex ~= nil then
		local expectedLoadout = PlEquipMySetList:get_element(lastHitLoadoutIndex);
		if isSamePlEquipPack_method:call(expectedLoadout) == true then
			return 1, PlEquipMySetData_get_Name_method:call(expectedLoadout), nil;
		end
	end

	for i = 0, 223, 1 do
		local PlEquipMySet = PlEquipMySetList:get_element(i);
		if isSamePlEquipPack_method:call(PlEquipMySet) == true then
			lastHitLoadoutIndex = i;
			return 1, PlEquipMySetData_get_Name_method:call(PlEquipMySet), nil;
		end
	end

	return 2, GetWeaponName(), true;
end
--
local this = {
	Restock = function(loadoutIndex)
		local ItemMySet = get_ItemMySet_method:call(nil);
		local loadout = getData_method:call(ItemMySet, DefaultSet);
		local itemLoadoutName = PlItemPouchMySetData_get_Name_method:call(loadout);
		local msg = string_format(LocalizedStrings.OutOfStock, itemLoadoutName);

		if isEnoughItem_method:call(loadout) == true then
			local matchedType, matchedName, loadoutMismatch = AutoChooseItemLoadout(Constants:get_EquipDataManager(), loadoutIndex);
			applyItemMySet_method:call(ItemMySet, DefaultSet);
			msg = matchedType == 1 and string_format(LocalizedStrings.FromLoadout, matchedName, itemLoadoutName)
				or matchedType == 2 and FromWeaponType(matchedName, itemLoadoutName, loadoutMismatch);
		end

		return msg;
	end
};
--
return this;