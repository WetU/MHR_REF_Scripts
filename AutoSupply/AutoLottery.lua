local Constants = _G.require("Constants.Constants");
--
local ipairs = Constants.lua.ipairs;

local find_type_definition = Constants.sdk.find_type_definition;
local get_managed_singleton = Constants.sdk.get_managed_singleton;

local getMoneyVal = Constants.getMoneyVal;
local sendItemToBox = Constants.sendItemToBox;
local addItemToBox = Constants.addItemToBox;
local SendMessage = Constants.SendMessage;
local SendItemInfoMessage = Constants.SendItemInfoMessage;
local getCountOfAll = Constants.getCountOfAll;
--
local get_refGuiItemShopLotMenu_method = Constants.type_definitions.GuiManager_type_def:get_method("get_refGuiItemShopLotMenu");

local GuiItemShopLotMenu_type_def = get_refGuiItemShopLotMenu_method:get_return_type();
local setLotInfoPaper_method = GuiItemShopLotMenu_type_def:get_method("setLotInfoPaper");
local setLotInfoPaper_MR_method = GuiItemShopLotMenu_type_def:get_method("setLotInfoPaper_MR");
--
local FacilityDataManager_type_def = Constants.type_definitions.FacilityDataManager_type_def;
local get_LobbyItemShop_method = FacilityDataManager_type_def:get_method("get_LobbyItemShop");
local invokeLotEvent_method = FacilityDataManager_type_def:get_method("invokeLotEvent(snow.facility.itemShop.ItemLotFunc.LotPaymentType, System.Boolean)");

local ItemShopFacility_type_def = get_LobbyItemShop_method:get_return_type();
local isSale_method = ItemShopFacility_type_def:get_method("isSale"); -- static
local get_ItemLotFunc_method = ItemShopFacility_type_def:get_method("get_ItemLotFunc");

local ItemLotFunc_type_def = get_ItemLotFunc_method:get_return_type();
local get_LotCost_method = ItemLotFunc_type_def:get_method("get_LotCost");
local get_MainItemData_method = ItemLotFunc_type_def:get_method("get_MainItemData");
local get_LotEventStatus_method = ItemLotFunc_type_def:get_method("get_LotEventStatus");
local getLotHighCount_method = ItemLotFunc_type_def:get_method("getLotHighCount");
local setLotHighCount_method = ItemLotFunc_type_def:get_method("setLotHighCount(System.UInt32)");
local initInventory_method = ItemLotFunc_type_def:get_method("initInventory");
local get_LotInventoryDataList_method = ItemLotFunc_type_def:get_method("get_LotInventoryDataList");
local sendItemBoxFukudamaPrize_method = ItemLotFunc_type_def:get_method("sendItemBoxFukudamaPrize");
local LotHighCountForPresent_field = ItemLotFunc_type_def:get_field("_LotHighCountForPresent");
--
local getItemId_method = get_MainItemData_method:get_return_type():get_method("getItemId");
--
local ItemInventoryData_type_def = Constants.type_definitions.ItemInventoryData_type_def;
local get_ItemId_method = ItemInventoryData_type_def:get_method("get_ItemId");
local get_Count_method = ItemInventoryData_type_def:get_method("get_Count");
local checkSendInventoryStatus_method = ItemInventoryData_type_def:get_method("checkSendInventoryStatus(snow.data.ItemInventoryData, snow.data.InventoryData.InventoryType, System.UInt32)"); -- static
--
local isMRReleased_method = find_type_definition("snow.progress.ProgressManager"):get_method("isMRReleased");

--getAddFukudamaPoints()
local this = {
    autoLot = function()
        if isSale_method:call(nil) == true then
            local FacilityDataManager = Constants:get_FacilityDataManager();
            local ItemLotFunc = get_ItemLotFunc_method:call(get_LobbyItemShop_method:call(FacilityDataManager));
            local LotEventStatus = get_LotEventStatus_method:call(ItemLotFunc);
            if LotEventStatus ~= 3 and LotEventStatus ~= 4 and LotEventStatus ~= 6 then
                local paymentType = getCountOfAll(68157531) > 0 and 1
                    or getMoneyVal() >= get_LotCost_method:call(ItemLotFunc) and 0
                    or nil;

                if paymentType == nil then
                    SendMessage("추첨권과 소지금이 없습니다!");
                    return;
                end

                local isMRReleased = isMRReleased_method:call(get_managed_singleton("snow.progress.ProgressManager")) == true;
                invokeLotEvent_method:call(FacilityDataManager, paymentType, isMRReleased);

                if getLotHighCount_method:call(ItemLotFunc) >= LotHighCountForPresent_field:get_data(ItemLotFunc) then
                    local GuiItemShopLotMenu = get_refGuiItemShopLotMenu_method:call(Constants:get_GuiManager());
                    setLotInfoPaper_method:call(GuiItemShopLotMenu);
                    if isMRReleased == true then
                        setLotInfoPaper_MR_method:call(GuiItemShopLotMenu);
                    end
                    addItemToBox(getItemId_method:call(get_MainItemData_method:call(ItemLotFunc)), 1);
                    setLotHighCount_method:call(ItemLotFunc, 0);
                end

                for _, Inventory in ipairs(get_LotInventoryDataList_method:call(ItemLotFunc):get_elements()) do
                    local count = get_Count_method:call(Inventory);

                    SendItemInfoMessage(get_ItemId_method:call(Inventory), count, checkSendInventoryStatus_method:call(nil, Inventory, 65536, count) == 0 and 0 or 1);
                    sendItemToBox(Inventory, true);
                end

                sendItemBoxFukudamaPrize_method:call(ItemLotFunc);
                initInventory_method:call(ItemLotFunc);
            end
        end
    end
};
--
return this;