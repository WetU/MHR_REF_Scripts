local Constants = require("Constants.Constants");
if not Constants then
    return;
end
--
local this = {};
--
local VillagePoint_type_def = Constants.SDK.find_type_definition("snow.data.VillagePoint");
local get_Point_method = VillagePoint_type_def:get_method("get_Point"); -- static, retval
local subPoint_method = VillagePoint_type_def:get_method("subPoint(System.UInt32)"); -- static

local get_TradeFunc_method = Constants.SDK.find_type_definition("snow.facility.TradeCenterFacility"):get_method("get_TradeFunc"); -- retval

local TradeFunc_type_def = get_TradeFunc_method:get_return_type();
local get_TradeOrderList_method = TradeFunc_type_def:get_method("get_TradeOrderList"); -- retval
local getNegotiationData_method = TradeFunc_type_def:get_method("getNegotiationData(snow.facility.tradeCenter.NegotiationTypes)"); -- retval

local TradeOrderList_type_def = get_TradeOrderList_method:get_return_type();
local TradeOrderList_get_Count_method = TradeOrderList_type_def:get_method("get_Count"); -- retval
local TradeOrderList_get_Item_method = TradeOrderList_type_def:get_method("get_Item(System.Int32)"); -- retval

local NegotiationData_type_def = getNegotiationData_method:get_return_type();
local get_Cost_method = NegotiationData_type_def:get_method("get_Cost"); -- retval
local NegotiationData_get_Count_method = NegotiationData_type_def:get_method("get_Count"); -- retval

local TradeOrder_type_def = TradeOrderList_get_Item_method:get_return_type();
local initialize_method = TradeOrder_type_def:get_method("initialize");
local get_InventoryList_method = TradeOrder_type_def:get_method("get_InventoryList"); -- retval
local get_NegotiationCount_method = TradeOrder_type_def:get_method("get_NegotiationCount"); -- retval
local setNegotiationCount_method = TradeOrder_type_def:get_method("setNegotiationCount(System.UInt32)");
local get_NegotiationType_method = TradeOrder_type_def:get_method("get_NegotiationType"); -- retval

local InventoryList_type_def = get_InventoryList_method:get_return_type();
local InventoryList_get_Count_method = InventoryList_type_def:get_method("get_Count"); -- retval
local InventoryList_get_Item_method = InventoryList_type_def:get_method("get_Item(System.Int32)"); -- retval

local Inventory_type_def = InventoryList_get_Item_method:get_return_type();
local isEmpty_method = Inventory_type_def:get_method("isEmpty"); -- retval
local Inventory_get_Count_method = Inventory_type_def:get_method("get_Count"); -- retval
local sendInventory_method = Inventory_type_def:get_method("sendInventory(snow.data.ItemInventoryData, snow.data.ItemInventoryData, System.UInt32)");

local trySellGameItem_method = Constants.type_definitions.DataManager_type_def:get_method("trySellGameItem(snow.data.ItemInventoryData, System.UInt32)");

local SendInventoryResult_AllSended = sendInventory_method:get_return_type():get_field("AllSended"):get_data(nil);
--
function this.autoArgosy()
    local TradeCenterFacility = Constants.SDK.get_managed_singleton("snow.facility.TradeCenterFacility");
    local DataManager = Constants.SDK.get_managed_singleton("snow.data.DataManager");
    if TradeCenterFacility ~= nil and DataManager ~= nil then
        local tradeFunc = get_TradeFunc_method:call(TradeCenterFacility);
        if tradeFunc ~= nil then
            local tradeOrderList = get_TradeOrderList_method:call(tradeFunc);
            if tradeOrderList ~= nil then
                local tradeOrderList_count = TradeOrderList_get_Count_method:call(tradeOrderList);
                if tradeOrderList_count > 0 then
                    local isReceived = false;
                    for i = 0, tradeOrderList_count - 1, 1 do
                        local tradeOrder = TradeOrderList_get_Item_method:call(tradeOrderList, i);
                        if tradeOrder ~= nil then
                            local negotiationCount = get_NegotiationCount_method:call(tradeOrder);
                            if negotiationCount == 1 then
                                local negotiationData = getNegotiationData_method:call(tradeFunc, get_NegotiationType_method:call(tradeOrder));
                                if negotiationData ~= nil then
                                    local negotiationCost = get_Cost_method:call(negotiationData);
                                    if negotiationCost ~= nil and get_Point_method:call(nil) >= negotiationCost then
                                        setNegotiationCount_method:call(tradeOrder, negotiationCount + NegotiationData_get_Count_method:call(negotiationData));
                                        subPoint_method:call(nil, negotiationCost);
                                    end
                                end
                            end

                            local inventoryList = get_InventoryList_method:call(tradeOrder);
                            if inventoryList ~= nil then
                                local inventoryList_count = InventoryList_get_Count_method:call(inventoryList);
                                if inventoryList_count > 0 then
                                    for j = 0, inventoryList_count - 1, 1 do
                                        local inventory = InventoryList_get_Item_method:call(inventoryList, i);
                                        if inventory ~= nil and not isEmpty_method:call(inventory) then
                                            if sendInventory_method:call(inventory, inventory, inventory, 65536) ~= SendInventoryResult_AllSended then
                                                trySellGameItem_method:call(DataManager, inventory, Inventory_get_Count_method:call(inventory));
                                            end
                                            isReceived = true;
                                        end
                                    end
                                end
                            end

                            initialize_method:call(tradeOrder);
                        end
                    end
                    return isReceived;
                end
            end
        end
    end
end

return this;