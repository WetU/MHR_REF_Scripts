local Constants = _G.require("Constants.Constants");
--
local ipairs = Constants.lua.ipairs;

local get_managed_singleton = Constants.sdk.get_managed_singleton;

local getMoneyVal = Constants.getMoneyVal;
local sendItemToBox = Constants.sendItemToBox;
local SendItemInfoMessage = Constants.SendItemInfoMessage;
--
local get_LobbyItemShop_method = Constants.type_definitions.FacilityDataManager_type_def:get_method("get_LobbyItemShop");

local ItemShopFacility_type_def = get_LobbyItemShop_method:get_return_type();
local isSale_method = ItemShopFacility_type_def:get_method("isSale"); -- static
local get_ItemLotFunc_method = ItemShopFacility_type_def:get_method("get_ItemLotFunc");

local ItemLotFunc_type_def = get_ItemLotFunc_method:get_return_type();
local resetLotParam_method = ItemLotFunc_type_def:get_method("resetLotParam");
local get_LotCost_method = ItemLotFunc_type_def:get_method("get_LotCost");
local getLotEventDoneFlag_method = ItemLotFunc_type_def:get_method("getLotEventDoneFlag");
local invokeLotEvent_method = ItemLotFunc_type_def:get_method("invokeLotEvent(snow.facility.itemShop.ItemLotFunc.LotPaymentType)");
local invokeFukudamaEvent_method = ItemLotFunc_type_def:get_method("invokeFukudamaEvent(snow.facility.itemShop.ItemLotFunc.LotPaymentType)");
local initInventory_method = ItemLotFunc_type_def:get_method("initInventory");
local get_LotInventoryDataList_method = ItemLotFunc_type_def:get_method("get_LotInventoryDataList");

local ItemInventoryData_type_def = Constants.type_definitions.ItemInventoryData_type_def;
local get_ItemId_method = ItemInventoryData_type_def:get_method("get_ItemId");
local get_Count_method = ItemInventoryData_type_def:get_method("get_Count");
local checkSendInventoryStatus_method = ItemInventoryData_type_def:get_method("checkSendInventoryStatus(snow.data.ItemInventoryData, snow.data.InventoryData.InventoryType, System.UInt32)"); -- static
--
local this = {
    autoLot = function()
        if isSale_method:call(nil) == true then
            local ItemLotFunc = get_ItemLotFunc_method:call(get_LobbyItemShop_method:call(Constants:get_FacilityDataManager()));

            if getLotEventDoneFlag_method:call(ItemLotFunc) == false then
                if getMoneyVal() < get_LotCost_method:call(ItemLotFunc) then
                    Constants:SendMessage("추첨: 소지금 부족!");
                    return;
                end

                resetLotParam_method:call(ItemLotFunc);
                invokeLotEvent_method:call(ItemLotFunc, 0);
                invokeFukudamaEvent_method:call(ItemLotFunc, 0);

                local LotInventoryDataList = get_LotInventoryDataList_method:call(ItemLotFunc);
                local ChatManager = get_managed_singleton("snow.gui.ChatManager");

                for _, Inventory in ipairs(LotInventoryDataList:get_elements()) do
                    local count = get_Count_method:call(Inventory);

                    SendItemInfoMessage(ChatManager, get_ItemId_method:call(Inventory), count, checkSendInventoryStatus_method:call(nil, Inventory, 65536, count) == 0 and 0 or 1);
                    sendItemToBox(Inventory, true);
                end

                initInventory_method:call(ItemLotFunc);
            end
        end
    end
};
--
return this;