local Constants = _G.require("Constants.Constants");
--
local ipairs = Constants.lua.ipairs;

local get_managed_singleton = Constants.sdk.get_managed_singleton;

local sendItemToBox = Constants.sendItemToBox;
local SendItemInfoMessage = Constants.SendItemInfoMessage;
local getCountOfAll = Constants.getCountOfAll;
--
local FacilityDataManager_type_def = Constants.type_definitions.FacilityDataManager_type_def;
local checkLotEventStatus_method = FacilityDataManager_type_def:get_method("checkLotEventStatus"); -- static
local invokeLotEvent_method = FacilityDataManager_type_def:get_method("invokeLotEvent(snow.facility.itemShop.ItemLotFunc.LotPaymentType, System.Boolean)");
local getItemShopPrizeInventoryList_method = FacilityDataManager_type_def:get_method("getItemShopPrizeInventoryList");

local ItemInventoryData_type_def = Constants.type_definitions.ItemInventoryData_type_def;
local get_ItemId_method = ItemInventoryData_type_def:get_method("get_ItemId");
local get_Count_method = ItemInventoryData_type_def:get_method("get_Count");
local checkSendInventoryStatus_method = ItemInventoryData_type_def:get_method("checkSendInventoryStatus(snow.data.ItemInventoryData, snow.data.InventoryData.InventoryType, System.UInt32)"); -- static
--
local this = {
    autoLot = function()
        local LotEventStatus = checkLotEventStatus_method:call(nil);
        if LotEventStatus ~= 6 and LotEventStatus ~= 3 and LotEventStatus ~= 4 then
            local FacilityDataManager = Constants:get_FacilityDataManager();
            local ChatManager = get_managed_singleton("snow.gui.ChatManager");
            invokeLotEvent_method:call(FacilityDataManager, getCountOfAll(68157531) > 0 and 1 or 0, true);

            for _, Inventory in ipairs(getItemShopPrizeInventoryList_method:call(FacilityDataManager):get_elements()) do
                local count = get_Count_method:call(Inventory);

                SendItemInfoMessage(ChatManager, get_ItemId_method:call(Inventory), count, checkSendInventoryStatus_method:call(nil, Inventory, 65536, count) == 0 and 0 or 1);
                sendItemToBox(Inventory, true);
            end
        end
    end
};
--
return this;