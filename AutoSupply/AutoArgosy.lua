local Constants = _G.require("Constants.Constants");

local ipairs = Constants.lua.ipairs;
local find_type_definition = Constants.sdk.find_type_definition;
local get_managed_singleton = Constants.sdk.get_managed_singleton;

local getVillagePoint = Constants.getVillagePoint;
local subVillagePoint = Constants.subVillagePoint;
--
local get_TradeFunc_method = find_type_definition("snow.facility.TradeCenterFacility"):get_method("get_TradeFunc");

local TradeFunc_type_def = get_TradeFunc_method:get_return_type();
local get_TradeOrderList_method = TradeFunc_type_def:get_method("get_TradeOrderList");
local getNegotiationData_method = TradeFunc_type_def:get_method("getNegotiationData(snow.facility.tradeCenter.NegotiationTypes)");

local NegotiationData_type_def = getNegotiationData_method:get_return_type();
local NegotiationData_get_Count_method = NegotiationData_type_def:get_method("get_Count");
local get_Cost_method = NegotiationData_type_def:get_method("get_Cost");

local TradeOrderData_type_def = find_type_definition("snow.facility.tradeCenter.TradeOrderData");
local initialize_method = TradeOrderData_type_def:get_method("initialize");
local get_InventoryList_method = TradeOrderData_type_def:get_method("get_InventoryList");
local get_NegotiationCount_method = TradeOrderData_type_def:get_method("get_NegotiationCount");
local setNegotiationCount_method = TradeOrderData_type_def:get_method("setNegotiationCount(System.UInt32)");
local get_NegotiationType_method = TradeOrderData_type_def:get_method("get_NegotiationType");

local DataShortcut_type_def = Constants.type_definitions.DataShortcut_type_def;
local findInventoryData_method = DataShortcut_type_def:get_method("findInventoryData(snow.data.InventoryData.InventoryGroup, snow.data.ContentsIdSystem.ItemId)"); -- staic
local sendItemToBox_method = DataShortcut_type_def:get_method("sendItemToBox(snow.data.ItemInventoryData, System.Boolean)"); -- staic

local ItemInventoryData_type_def = findInventoryData_method:get_return_type();
local isEmpty_method = ItemInventoryData_type_def:get_method("isEmpty");
local sub_method = ItemInventoryData_type_def:get_method("sub(System.UInt32, System.Boolean)");
--
local cacheNegotiationData = nil;
--
local function mkTable()
	local table = {
		[0] = true,
		[1] = true,
		[2] = true,
		[3] = true,
		[4] = true,
		[5] = true
	};

	return table;
end

local function buildCache(tradeFunc)
	if cacheNegotiationData == nil then
		cacheNegotiationData = {
			Count = mkTable(),
			Cost = mkTable()
		};

		for i = 0, 5, 1 do
			local NegotiationData = getNegotiationData_method:call(tradeFunc, i);
			cacheNegotiationData.Count[i] = NegotiationData_get_Count_method:call(NegotiationData);
			cacheNegotiationData.Cost[i] = get_Cost_method:call(NegotiationData);
		end
	end
end

local this = {
	autoArgosy = function()
		local TradeFunc = get_TradeFunc_method:call(get_managed_singleton("snow.facility.TradeCenterFacility"));
		buildCache(TradeFunc);

		local countUpdated = false;
		local inventoryReceived = false;
		local isReceived = false;
		local acornInventoryData = findInventoryData_method:call(nil, 1, 68158481);
		local addCount = isEmpty_method:call(acornInventoryData) == true and 1 or 4;

		for _, TradeOrder in ipairs(get_TradeOrderList_method:call(TradeFunc):get_elements()) do
			if get_NegotiationCount_method:call(TradeOrder) == 1 then
				local addNegoCount = addCount;
				local NegotiationType = get_NegotiationType_method:call(TradeOrder);
				local NegotiationCostData = cacheNegotiationData.Cost[NegotiationType];

				if getVillagePoint() >= NegotiationCostData then
					addNegoCount = addNegoCount + cacheNegotiationData.Count[NegotiationType];
					subVillagePoint(NegotiationCostData);
				end

				if addNegoCount > 1 then
					setNegotiationCount_method:call(TradeOrder, addNegoCount);
					countUpdated = true;
				end
			end

			for _, Inventory in ipairs(get_InventoryList_method:call(TradeOrder):get_elements()) do
				if Inventory == nil or isEmpty_method:call(Inventory) == true then
					break;
				else
					sendItemToBox_method:call(nil, Inventory, true);
					inventoryReceived = true;
				end
			end

			if inventoryReceived == true then
				initialize_method:call(TradeOrder);
				isReceived = isReceived or inventoryReceived;
			end
		end

		if addCount > 1 and countUpdated == true then
			sub_method:call(acornInventoryData, 1, true);
		end

		return isReceived;
	end
};
--
return this;