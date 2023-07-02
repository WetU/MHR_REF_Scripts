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
        local TradeFunc = get_TradeFunc_method:call(TradeCenterFacility);
        if TradeFunc ~= nil then
            local TradeOrderList = get_TradeOrderList_method:call(TradeFunc);
            if TradeOrderList ~= nil then
                local TradeOrderList_count = TradeOrderList_get_Count_method:call(TradeOrderList);
                if TradeOrderList_count > 0 then
                    local isReceived = false;
                    for i = 0, TradeOrderList_count - 1, 1 do
                        local TradeOrder = TradeOrderList_get_Item_method:call(TradeOrderList, i);
                        if TradeOrder ~= nil then
                            local NegotiationCount = get_NegotiationCount_method:call(TradeOrder);
                            local NegotiationType = get_NegotiationType_method:call(TradeOrder);
                            if NegotiationCount == 1 and NegotiationType ~= nil then
                                local NegotiationData = getNegotiationData_method:call(TradeFunc, NegotiationType);
                                if NegotiationData ~= nil then
                                    local NegotiationData_count = NegotiationData_get_Count_method:call(NegotiationData);
                                    local Cost = get_Cost_method:call(NegotiationData);
                                    if NegotiationData_count ~= nil and Cost ~= nil and get_Point_method:call(nil) >= Cost then
                                        setNegotiationCount_method:call(TradeOrder, NegotiationCount + NegotiationData_count);
                                        subPoint_method:call(nil, Cost);
                                    end
                                end
                            end

                            local InventoryList = get_InventoryList_method:call(TradeOrder);
                            if InventoryList ~= nil then
                                local InventoryList_count = InventoryList_get_Count_method:call(InventoryList);
                                if InventoryList_count > 0 then
                                    for j = 0, InventoryList_count - 1, 1 do
                                        local Inventory = InventoryList_get_Item_method:call(InventoryList, i);
                                        if Inventory ~= nil and not isEmpty_method:call(Inventory) then
                                            if sendInventory_method:call(Inventory, Inventory, Inventory, 65536) ~= SendInventoryResult_AllSended then
                                                trySellGameItem_method:call(DataManager, Inventory, Inventory_get_Count_method:call(Inventory));
                                            end
                                            isReceived = true;
                                        end
                                    end
                                end
                            end
                            initialize_method:call(TradeOrder);
                        end
                    end
                    return isReceived;
                end
            end
        end
    end
end

return this;