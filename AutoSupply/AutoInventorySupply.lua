local Constants = _G.require("Constants.Constants");
--
local string_format = Constants.lua.string_format;

local find_type_definition = Constants.sdk.find_type_definition;
--
local DefaultSet = 0;
--
local get_ItemMySet_method = find_type_definition("snow.data.DataManager"):get_method("get_ItemMySet"); -- static

local ItemMySet_type_def = get_ItemMySet_method:get_return_type();
local applyItemMySet_method = ItemMySet_type_def:get_method("applyItemMySet(System.Int32)");
local getData_method = ItemMySet_type_def:get_method("getData(System.Int32)");

local isEnoughItem_method = getData_method:get_return_type():get_method("isEnoughItem");
--
local get_PlEquipMySetList_method = Constants.type_definitions.EquipDataManager_type_def:get_method("get_PlEquipMySetList");

local PlEquipMySetData_type_def = find_type_definition("snow.equip.PlEquipMySetData");
local PlEquipMySetData_get_Name_method = PlEquipMySetData_type_def:get_method("get_Name");
local isSamePlEquipPack_method = PlEquipMySetData_type_def:get_method("isSamePlEquipPack");
--
local LocalizedStrings = {
	FromLoadout = "장비 프리셋 [<COL YEL>%s</COL>]",
	MismatchLoadout = "현재 장비와 일치하는 프리셋이 없습니다.",
	OutOfStock = "아이템 프리셋의 <COL RED>물품이 부족</COL>하여 적용이 취소되었습니다."
};
--
local lastHitLoadoutIndex = nil;

local function AutoChooseItemLoadout(equipDataManager, expectedLoadoutIndex)
	local PlEquipMySetList = get_PlEquipMySetList_method:call(equipDataManager);

	if expectedLoadoutIndex ~= nil then
		lastHitLoadoutIndex = expectedLoadoutIndex;
		return 1, PlEquipMySetData_get_Name_method:call(PlEquipMySetList:get_element(expectedLoadoutIndex));
	end

	if lastHitLoadoutIndex ~= nil then
		local expectedLoadout = PlEquipMySetList:get_element(lastHitLoadoutIndex);
		if isSamePlEquipPack_method:call(expectedLoadout) == true then
			return 1, PlEquipMySetData_get_Name_method:call(expectedLoadout);
		end
	end

	for i = 0, 223, 1 do
		local PlEquipMySet = PlEquipMySetList:get_element(i);
		if isSamePlEquipPack_method:call(PlEquipMySet) == true then
			lastHitLoadoutIndex = i;
			return 1, PlEquipMySetData_get_Name_method:call(PlEquipMySet);
		end
	end

	return 2, nil;
end
--
local this = {
	Restock = function(loadoutIndex)
		local ItemMySet = get_ItemMySet_method:call(nil);
		local msg = LocalizedStrings.OutOfStock;

		if isEnoughItem_method:call(getData_method:call(ItemMySet, DefaultSet)) == true then
			applyItemMySet_method:call(ItemMySet, DefaultSet);
			local matchedType, matchedName = AutoChooseItemLoadout(Constants:get_EquipDataManager(), loadoutIndex);
			msg = matchedType == 1 and string_format(LocalizedStrings.FromLoadout, matchedName)
				or matchedType == 2 and LocalizedStrings.MismatchLoadout;
		end

		return msg;
	end
};
--
return this;