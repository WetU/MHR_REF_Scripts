local Constants = _G.require("Constants.Constants");

local find_type_definition = Constants.sdk.find_type_definition;

local findInventoryData = Constants.findInventoryData;
local getVillagePoint = Constants.getVillagePoint;
local subVillagePoint = Constants.subVillagePoint;
--
local sendItemToBox_method = Constants.type_definitions.DataShortcut_type_def:get_method("sendItemToBox(snow.data.ItemInventoryData, System.Boolean)"); -- static

local get_TradeFunc_method = find_type_definition("snow.facility.TradeCenterFacility"):get_method("get_TradeFunc");
local get_TradeOrderList_method = get_TradeFunc_method:get_return_type():get_method("get_TradeOrderList");

local TradeOrderData_type_def = find_type_definition("snow.facility.tradeCenter.TradeOrderData");
local initialize_method = TradeOrderData_type_def:get_method("initialize");
local get_InventoryList_method = TradeOrderData_type_def:get_method("get_InventoryList");
local get_NegotiationCount_method = TradeOrderData_type_def:get_method("get_NegotiationCount");
local setNegotiationCount_method = TradeOrderData_type_def:get_method("setNegotiationCount(System.UInt32)");
local get_NegotiationType_method = TradeOrderData_type_def:get_method("get_NegotiationType");

local ItemInventoryData_type_def = Constants.type_definitions.ItemInventoryData_type_def;
local isEmpty_method = ItemInventoryData_type_def:get_method("isEmpty");
local sub_method = ItemInventoryData_type_def:get_method("sub(System.UInt32, System.Boolean)");
--
local negotiationData = {
	Count = {6, 3, 3, 6, 3, 3},
	Cost = {100, 150, 300, 250, 300, 500}
};
--
local this = {
	autoArgosy = function()
		local countUpdated = false;
		local isReceived = false;
		local acornInventoryData = findInventoryData(1, 68158481);
		local addCount = (acornInventoryData == nil or isEmpty_method:call(acornInventoryData) == true) and 1 or 4;

		local TradeOrderList = get_TradeOrderList_method:call(get_TradeFunc_method:call(Constants:get_TradeCenterFacility()));

		for i = 0, 2, 1 do
			local TradeOrder = TradeOrderList:get_element(i);

			if get_NegotiationCount_method:call(TradeOrder) == 1 then
				local addNegoCount = addCount;
				local NegotiationType = get_NegotiationType_method:call(TradeOrder) + 1;
				local NegotiationCostData = negotiationData.Cost[NegotiationType];

				if getVillagePoint() >= NegotiationCostData then
					addNegoCount = addNegoCount + negotiationData.Count[NegotiationType];
					subVillagePoint(NegotiationCostData);
				end

				if addNegoCount > 1 then
					setNegotiationCount_method:call(TradeOrder, addNegoCount);
					countUpdated = true;
				end
			end

			local InventoryList = get_InventoryList_method:call(TradeOrder);

			for j = 0, 19, 1 do
				local Inventory = InventoryList:get_element(j);

				if Inventory == nil or isEmpty_method:call(Inventory) == true then
					break;
				end

				sendItemToBox_method:call(nil, Inventory, true);
				isReceived = true;
			end

			initialize_method:call(TradeOrder);
		end

		if addCount > 1 and countUpdated == true then
			sub_method:call(acornInventoryData, 1, true);
		end

		return isReceived;
	end
};
--
return this;