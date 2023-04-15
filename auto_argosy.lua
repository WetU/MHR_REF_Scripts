local sdk = sdk
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
local sdk_hook = sdk.hook;

local pairs = pairs;
--
local getCurrentMapNo_method = sdk_find_type_definition("snow.VillageMapManager"):get_method("getCurrentMapNo");
local reqAddChatItemInfo_method = sdk_find_type_definition("snow.gui.ChatManager"):get_method("reqAddChatItemInfo(snow.data.ContentsIdSystem.ItemId, System.Int32, snow.gui.ChatManager.ItemMaxType, System.Boolean)");
local get_TradeFunc_method = sdk_find_type_definition("snow.facility.TradeCenterFacility"):get_method("get_TradeFunc");

local TradeFunc_type_def = get_TradeFunc_method:get_return_type();
local get_TradeOrderList_method = TradeFunc_type_def:get_method("get_TradeOrderList");
local getNegotiationData_method = TradeFunc_type_def:get_method("getNegotiationData")

local NegotiationData_type_def = getNegotiationData_method:get_return_type();
local get_Cost_method = NegotiationData_type_def:get_method("get_Cost");
local NegotiationData_get_Count_method = NegotiationData_type_def:get_method("get_Count");

local TradeOrder_type_def = sdk_find_type_definition("snow.facility.tradeCenter.TradeOrderData");
local initialize_method = TradeOrder_type_def:get_method("initialize");
local get_InventoryList_method = TradeOrder_type_def:get_method("get_InventoryList");
local get_NegotiationCount_method = TradeOrder_type_def:get_method("get_NegotiationCount");
local setNegotiationCount_method = TradeOrder_type_def:get_method("setNegotiationCount");
local get_NegotiationType_method = TradeOrder_type_def:get_method("get_NegotiationType");

local Inventory_type_def = sdk_find_type_definition("snow.data.ItemInventoryData");
local isEmpty_method = Inventory_type_def:get_method("isEmpty");
local get_ItemId_method = Inventory_type_def:get_method("get_ItemId");
local Inventory_get_Count_method = Inventory_type_def:get_method("get_Count");
local sendInventory_method = Inventory_type_def:get_method("sendInventory(snow.data.ItemInventoryData, snow.data.InventoryData.InventoryType)");

local DataManager_type_def = sdk_find_type_definition("snow.data.DataManager");
local getVillagePoint_method = DataManager_type_def:get_method("getVillagePoint");
local trySellGameItem_method = DataManager_type_def:get_method("trySellGameItem(snow.data.ItemInventoryData, System.UInt32)");

local VillagePoint_type_def = getVillagePoint_method:get_return_type();
local get_Point_method = VillagePoint_type_def:get_method("get_Point");
local subPoint_method = VillagePoint_type_def:get_method("subPoint");
--
local maxTypeOver = sdk_find_type_definition("snow.gui.ChatManager.ItemMaxType"):get_field("OverMax"):get_data(nil);
--
local itemBoxId = 65536
local Result = {
    All = 0,
    Some = 1,
    Full = 2,
    Max = 3
};

local function autoArgosy()
    local TradeCenterFacility = sdk_get_managed_singleton("snow.facility.TradeCenterFacility");
    if TradeCenterFacility then
        local tradeFunc = get_TradeFunc_method:call(TradeCenterFacility);
        if tradeFunc then
            local tradeOrderList = get_TradeOrderList_method:call(tradeFunc);
            if tradeOrderList then
                local DataManager = sdk_get_managed_singleton("snow.data.DataManager");
                local argosyItems = {};
                local itemBoxResults = {};
                if DataManager then
                    for i = 0, #tradeOrderList - 1, 1 do
                        local tradeOrder = tradeOrderList:get_element(i);
                        if tradeOrder then
                            local inventoryList = get_InventoryList_method:call(tradeOrder);
                            local negotiationCount = get_NegotiationCount_method:call(tradeOrder);

                            if negotiationCount == 1 then
                                local negotiationData = getNegotiationData_method:call(tradeFunc, get_NegotiationType_method:call(tradeOrder));
                                local negotiationCost = get_Cost_method:call(negotiationData);
                                if negotiationData and negotiationCost then
                                    local villagePoint = getVillagePoint_method:call(DataManager);
                                    if villagePoint and get_Point_method:call(villagePoint) >= negotiationCost then
                                        setNegotiationCount_method:call(tradeOrder, negotiationCount + NegotiationData_get_Count_method:call(negotiationData));
                                        subPoint_method:call(villagePoint, negotiationCost);
                                    end
                                end
                            end

                            for j = 0, #inventoryList - 1, 1 do
                                local inventory = inventoryList:get_element(j);
                                if inventory and not isEmpty_method:call(inventory) then
                                    local itemId = get_ItemId_method:call(inventory);
                                    local count = Inventory_get_Count_method:call(inventory);
                                    if argosyItems[itemId] then
                                        argosyItems[itemId] = argosyItems[itemId] + count;
                                    else
                                        argosyItems[itemId] = count;
                                    end
                                    
                                    local sendResult = sendInventory_method:call(inventory, inventory, itemBoxId);
                                    itemBoxResults[itemId] = sendResult;

                                    if sendResult ~= Result.All then
                                        trySellGameItem_method:call(DataManager, inventory, Inventory_get_Count_method:call(inventory));
                                    end
                                end
                            end

                            initialize_method:call(tradeOrder);
                        end
                    end

                    local ChatManager = sdk_get_managed_singleton("snow.gui.ChatManager");
                    if ChatManager then
                        for i, v in pairs(argosyItems) do
                            if v ~= 0 then
                                local sendResult = itemBoxResults[i];
                                local maxType = sendResult;
                                if sendResult == Result.Max or sendResult == Result.Some then
                                    maxType = maxTypeOver;
                                end
                                reqAddChatItemInfo_method:call(ChatManager, i, v, maxType, false);
                            end
                        end
                    end
                end
            end
        end
    end
end

sdk_hook(getCurrentMapNo_method, nil, autoArgosy);
