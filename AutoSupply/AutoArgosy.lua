local Constants = _G.require("Constants.Constants");

local find_type_definition = Constants.sdk.find_type_definition;
local get_managed_singleton = Constants.sdk.get_managed_singleton;
--
local VillagePoint_type_def = find_type_definition("snow.data.VillagePoint");
local get_Point_method = VillagePoint_type_def:get_method("get_Point"); -- static
local subPoint_method = VillagePoint_type_def:get_method("subPoint(System.UInt32)"); -- static
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

local ItemInventoryData_type_def = find_type_definition("snow.data.ItemInventoryData");
local Inventory_get_Count_method = ItemInventoryData_type_def:get_method("get_Count");
local isEmpty_method = ItemInventoryData_type_def:get_method("isEmpty");
local sub_method = ItemInventoryData_type_def:get_method("sub(System.UInt32, System.Boolean)");
local sendInventory_method = ItemInventoryData_type_def:get_method("sendInventory(snow.data.ItemInventoryData, snow.data.InventoryData.InventoryType)"); -- static

local DataManager_type_def = Constants.type_definitions.DataManager_type_def;
local trySellGameItem_method = DataManager_type_def:get_method("trySellGameItem(snow.data.ItemInventoryData, System.UInt32)");
local getItemBox_method = DataManager_type_def:get_method("getItemBox");

local findInventoryData_method = getItemBox_method:get_return_type():get_method("findInventoryData(snow.data.ContentsIdSystem.ItemId)");
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

local function isAcornEnough(dataManager)
	local acornInventoryData = findInventoryData_method:call(getItemBox_method:call(dataManager), 68158481);
	local isAvailable = not isEmpty_method:call(acornInventoryData);
	return acornInventoryData, isAvailable;
end

local this = {
	autoArgosy = function()
		local DataManager = get_managed_singleton("snow.data.DataManager");
		local TradeFunc = get_TradeFunc_method:call(get_managed_singleton("snow.facility.TradeCenterFacility"));
		local TradeOrderList = get_TradeOrderList_method:call(TradeFunc);
		buildCache(TradeFunc);

		local countUpdated = false;
		local isReceived = false;
		local acornInventoryData, acornAvailable = isAcornEnough(DataManager);
		local addCount = acornAvailable == true and (1 + 3) or 1;

		for i = 0, TradeOrderList:get_size() - 1, 1 do
			local TradeOrder = TradeOrderList:get_element(i);
			if get_NegotiationCount_method:call(TradeOrder) == 1 then
				local addNegoCount = addCount;
				local NegotiationType = get_NegotiationType_method:call(TradeOrder);
				local NegotiationCostData = cacheNegotiationData.Cost[NegotiationType];

				if get_Point_method:call(nil) >= NegotiationCostData then
					addNegoCount = addNegoCount + cacheNegotiationData.Count[NegotiationType];
					subPoint_method:call(nil, NegotiationCostData);
				end

				if addNegoCount > 1 then
					setNegotiationCount_method:call(TradeOrder, addNegoCount);
					countUpdated = true;
				end
			end

			local InventoryList = get_InventoryList_method:call(TradeOrder);
			local inventoryReceived = false;

			for j = 0, InventoryList:get_size() - 1, 1 do
				local Inventory = InventoryList:get_element(j);
				if Inventory == nil or isEmpty_method:call(Inventory) == true then
					break;
				else
					local sendResult = sendInventory_method:call(nil, Inventory, 65536);
					if sendResult ~= nil and sendResult ~= 4 then
						inventoryReceived = true;
						if sendResult ~= 0 then
							trySellGameItem_method:call(DataManager, Inventory, Inventory_get_Count_method:call(Inventory));
						end
					end
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