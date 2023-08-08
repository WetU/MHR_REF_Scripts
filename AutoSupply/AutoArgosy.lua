local Constants = _G.require("Constants.Constants");

local find_type_definition = Constants.sdk.find_type_definition;
local get_managed_singleton = Constants.sdk.get_managed_singleton;

local get_VillagePoint = Constants.get_VillagePoint;
--
local subPoint_method = Constants.type_definitions.VillagePoint_type_def:get_method("subPoint(System.UInt32)"); -- static

local get_TradeFunc_method = find_type_definition("snow.facility.TradeCenterFacility"):get_method("get_TradeFunc");

local TradeFunc_type_def = get_TradeFunc_method:get_return_type();
local get_TradeOrderList_method = TradeFunc_type_def:get_method("get_TradeOrderList");
local getNegotiationData_method = TradeFunc_type_def:get_method("getNegotiationData(snow.facility.tradeCenter.NegotiationTypes)");
local AcornAddCount = TradeFunc_type_def:get_field("_AcornAddCount"):get_data(nil);

local TradeOrderList_type_def = get_TradeOrderList_method:get_return_type();
local TradeOrderList_get_Count_method = TradeOrderList_type_def:get_method("get_Count");
local TradeOrderList_get_Item_method = TradeOrderList_type_def:get_method("get_Item(System.Int32)");

local NegotiationData_type_def = getNegotiationData_method:get_return_type();
local NegotiationData_get_Count_method = NegotiationData_type_def:get_method("get_Count");
local get_Cost_method = NegotiationData_type_def:get_method("get_Cost");

local TradeOrder_type_def = TradeOrderList_get_Item_method:get_return_type();
local initialize_method = TradeOrder_type_def:get_method("initialize");
local get_InventoryList_method = TradeOrder_type_def:get_method("get_InventoryList");
local get_NegotiationCount_method = TradeOrder_type_def:get_method("get_NegotiationCount");
local setNegotiationCount_method = TradeOrder_type_def:get_method("setNegotiationCount(System.UInt32)");
local get_NegotiationType_method = TradeOrder_type_def:get_method("get_NegotiationType");

local InventoryList_type_def = get_InventoryList_method:get_return_type();
local InventoryList_get_Count_method = InventoryList_type_def:get_method("get_Count");
local InventoryList_get_Item_method = InventoryList_type_def:get_method("get_Item(System.Int32)");

local Inventory_type_def = InventoryList_get_Item_method:get_return_type();
local Inventory_get_Count_method = Inventory_type_def:get_method("get_Count");
local isEmpty_method = Inventory_type_def:get_method("isEmpty");
local sub_method = Inventory_type_def:get_method("sub(System.UInt32, System.Boolean)");
local sendInventory_method = Inventory_type_def:get_method("sendInventory(snow.data.ItemInventoryData, snow.data.InventoryData.InventoryType)"); -- static

local DataManager_type_def = Constants.type_definitions.DataManager_type_def;
local trySellGameItem_method = DataManager_type_def:get_method("trySellGameItem(snow.data.ItemInventoryData, System.UInt32)");
local getItemBox_method = DataManager_type_def:get_method("getItemBox");

local findInventoryData_method = getItemBox_method:get_return_type():get_method("findInventoryData(snow.data.ContentsIdSystem.ItemId)");
--
local NegotiationTypes_type_def = get_NegotiationType_method:get_return_type();
local NegotiationTypes = {
    NegotiationTypes_type_def:get_field("Negotiation_000"):get_data(nil),
    NegotiationTypes_type_def:get_field("Negotiation_001"):get_data(nil),
    NegotiationTypes_type_def:get_field("Negotiation_002"):get_data(nil),
    NegotiationTypes_type_def:get_field("Negotiation_003"):get_data(nil),
    NegotiationTypes_type_def:get_field("Negotiation_004"):get_data(nil),
    NegotiationTypes_type_def:get_field("Negotiation_005"):get_data(nil)
};

local Acorn_Id = Constants.type_definitions.ItemId_type_def:get_field("I_Normal_1041"):get_data(nil);
local PlayerItemBox = find_type_definition("snow.data.InventoryData.InventoryType"):get_field("PlayerItemBox"):get_data(nil);
local SendInventoryResult_type_def = sendInventory_method:get_return_type();
local SendInventoryResult = {
    AllSended = SendInventoryResult_type_def:get_field("AllSended"):get_data(nil),
    Error = SendInventoryResult_type_def:get_field("Error"):get_data(nil)
};
--
local cacheNegotiationData = nil;
--
local function mkTable()
    local table = {
        true,
        true,
        true,
        true,
        true,
        true
    };

    return table;
end

local function buildCache(tradeFunc)
    if cacheNegotiationData == nil then
        cacheNegotiationData = {
            Count = mkTable(),
            Cost = mkTable()
        };

        for i = 1, 6, 1 do
            local NegotiationData = getNegotiationData_method:call(tradeFunc, NegotiationTypes[i]);
            cacheNegotiationData.Count[i] = NegotiationData_get_Count_method:call(NegotiationData);
            cacheNegotiationData.Cost[i] = get_Cost_method:call(NegotiationData);
        end
    end
end

local function isAcornEnough(dataManager)
    local acornInventoryData = findInventoryData_method:call(getItemBox_method:call(dataManager), Acorn_Id);
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
        local addCount = acornAvailable == true and (1 + AcornAddCount) or 1;

        for i = 0, TradeOrderList_get_Count_method:call(TradeOrderList) - 1, 1 do
            local TradeOrder = TradeOrderList_get_Item_method:call(TradeOrderList, i);
            if get_NegotiationCount_method:call(TradeOrder) == 1 then
                local addNegoCount = addCount;
                local NegotiationType = get_NegotiationType_method:call(TradeOrder) + 1;
                local NegotiationCountData = cacheNegotiationData.Count[NegotiationType];
                local NegotiationCostData = cacheNegotiationData.Cost[NegotiationType];

                if get_VillagePoint() >= NegotiationCostData then
                    addNegoCount = addNegoCount + NegotiationCountData;
                    subPoint_method:call(nil, NegotiationCostData);
                end

                if addNegoCount > 1 then
                    setNegotiationCount_method:call(TradeOrder, addNegoCount);
                    countUpdated = true;
                end
            end

            local InventoryList = get_InventoryList_method:call(TradeOrder);
            local inventoryReceived = false;

            for j = 0, InventoryList_get_Count_method:call(InventoryList) - 1, 1 do
                local Inventory = InventoryList_get_Item_method:call(InventoryList, j);
                if Inventory == nil or isEmpty_method:call(Inventory) == true then
                    break;
                else
                    local sendResult = sendInventory_method:call(nil, Inventory, PlayerItemBox);
                    if sendResult ~= nil and sendResult ~= SendInventoryResult.Error then
                        inventoryReceived = true;
                        if sendResult ~= SendInventoryResult.AllSended then
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