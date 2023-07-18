local Constants = require("Constants.Constants");
if not Constants then
    return;
end
--
local this = {};
--
local VillagePoint_type_def = Constants.SDK.find_type_definition("snow.data.VillagePoint");
local get_Point_method = VillagePoint_type_def:get_method("get_Point"); -- static
local subPoint_method = VillagePoint_type_def:get_method("subPoint(System.UInt32)"); -- static

local get_TradeFunc_method = Constants.SDK.find_type_definition("snow.facility.TradeCenterFacility"):get_method("get_TradeFunc");

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

local trySellGameItem_method = Constants.type_definitions.DataManager_type_def:get_method("trySellGameItem(snow.data.ItemInventoryData, System.UInt32)");
local getItemBox_method = Constants.type_definitions.DataManager_type_def:get_method("getItemBox");

local findInventoryData_method = getItemBox_method:get_return_type():get_method("findInventoryData(snow.data.ContentsIdSystem.ItemId)");

local Acorn_Id = Constants.SDK.find_type_definition("snow.data.ContentsIdSystem.ItemId"):get_field("I_Normal_1041"):get_data(nil);
local PlayerItemBox = Constants.SDK.find_type_definition("snow.data.InventoryData.InventoryType"):get_field("PlayerItemBox"):get_data(nil);
local SendInventoryResult_type_def = sendInventory_method:get_return_type();
local SendInventoryResult = {
    AllSended = SendInventoryResult_type_def:get_field("AllSended"):get_data(nil),
    Error = SendInventoryResult_type_def:get_field("Error"):get_data(nil)
};
--
local function isAcornEnough(dataManager)
    local ItemBox = getItemBox_method:call(dataManager);
    if ItemBox ~= nil then
        local acornInventoryData = findInventoryData_method:call(ItemBox, Acorn_Id);
        if acornInventoryData ~= nil then
            return acornInventoryData, Inventory_get_Count_method:call(acornInventoryData) > 0;
        end
    end
    return nil, nil;
end

function this.autoArgosy()
    local DataManager = Constants.SDK.get_managed_singleton("snow.data.DataManager");
    local TradeCenterFacility = Constants.SDK.get_managed_singleton("snow.facility.TradeCenterFacility");
    if DataManager ~= nil and TradeCenterFacility ~= nil then
        local TradeFunc = get_TradeFunc_method:call(TradeCenterFacility);
        if TradeFunc ~= nil then
            local TradeOrderList = get_TradeOrderList_method:call(TradeFunc);
            if TradeOrderList ~= nil then
                local TradeOrderList_count = TradeOrderList_get_Count_method:call(TradeOrderList);
                if TradeOrderList_count > 0 then
                    local updateNegotiation = false;
                    local isReceived = false;
                    local acornInventoryData, acornAvailable = isAcornEnough(DataManager);

                    for i = 0, TradeOrderList_count - 1, 1 do
                        local TradeOrder = TradeOrderList_get_Item_method:call(TradeOrderList, i);
                        if TradeOrder ~= nil then
                            local NegotiationCount = get_NegotiationCount_method:call(TradeOrder);
                            if NegotiationCount == 1 then
                                local NegotiationType = get_NegotiationType_method:call(TradeOrder);
                                if NegotiationType ~= nil then
                                    local NegotiationData = getNegotiationData_method:call(TradeFunc, NegotiationType);
                                    if NegotiationData ~= nil then
                                        local Cost = get_Cost_method:call(NegotiationData);
                                        if Cost ~= nil then
                                            if get_Point_method:call(nil) >= Cost then
                                                local NegotiationData_count = NegotiationData_get_Count_method:call(NegotiationData);
                                                if NegotiationData_count ~= nil then
                                                    subPoint_method:call(nil, Cost);
                                                    setNegotiationCount_method:call(TradeOrder, acornAvailable == true and (NegotiationCount + AcornAddCount + NegotiationData_count) or (NegotiationCount + NegotiationData_count));
                                                    updateNegotiation = true;
                                                end
                                            elseif acornAvailable == true then
                                                setNegotiationCount_method:call(TradeOrder, NegotiationCount + AcornAddCount);
                                                updateNegotiation = true;
                                            end
                                        end
                                    end
                                end
                            end

                            local InventoryList = get_InventoryList_method:call(TradeOrder);
                            if InventoryList ~= nil then
                                local InventoryList_count = InventoryList_get_Count_method:call(InventoryList);
                                if InventoryList_count > 0 then
                                    local inventoryReceived = false;
                                    for j = 0, InventoryList_count - 1, 1 do
                                        local Inventory = InventoryList_get_Item_method:call(InventoryList, j);
                                        if Inventory ~= nil and isEmpty_method:call(Inventory) == false then
                                            local sendResult = sendInventory_method:call(nil, Inventory, PlayerItemBox);
                                            if sendResult ~= nil then
                                                if sendResult ~= SendInventoryResult.Error then
                                                    if sendResult ~= SendInventoryResult.AllSended then
                                                        local itemCount = Inventory_get_Count_method:call(Inventory);
                                                        if itemCount ~= nil then
                                                            trySellGameItem_method:call(DataManager, Inventory, itemCount);
                                                        end
                                                    end
                                                    inventoryReceived = true;
                                                end
                                            end
                                        end
                                    end
                                    if inventoryReceived == true then
                                        initialize_method:call(TradeOrder);
                                        isReceived = isReceived or inventoryReceived;
                                    end
                                end
                            end
                        end
                    end

                    if acornAvailable == true and updateNegotiation == true then
                        sub_method:call(acornInventoryData, 1, true);
                    end

                    return isReceived;
                end
            end
        end
    end
    return nil;
end
--
return this;