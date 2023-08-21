local Constants = _G.require("Constants.Constants");
--
local SendMessage = Constants.SendMessage;
local getCountOfAll = Constants.getCountOfAll;
--
local MysteryLaboTradePointItemFacility_type_def = Constants.sdk.find_type_definition("snow.facility.MysteryLaboTradePointItemFacility");
local get__OtherItemDataList_method = MysteryLaboTradePointItemFacility_type_def:get_method("get__OtherItemDataList");
local getMaxExchangeableNum_method = MysteryLaboTradePointItemFacility_type_def:get_method("getMaxExchangeableNum(snow.facility.mysteryLabo.MysteryLaboTradeItemData)");
local checkExchangeStatus_method = MysteryLaboTradePointItemFacility_type_def:get_method("checkExchangeStatus(snow.facility.mysteryLabo.MysteryLaboTradeItemData, System.UInt32)");
local exchange_method = MysteryLaboTradePointItemFacility_type_def:get_method("exchange(snow.facility.mysteryLabo.MysteryLaboTradeItemData, System.UInt32)");

local get_Item_method = get__OtherItemDataList_method:get_return_type():get_method("get_Item(System.Int32)");
--
local PLATINUM_EGG_DATA = nil;
local this = {
    exchange = function()
        if getCountOfAll(68160340) >= 9999 then
            local MysteryLaboTradePointItemFacility = Constants:get_MysteryLaboTradePointItemFacility();

            if PLATINUM_EGG_DATA == nil then
                PLATINUM_EGG_DATA = get_Item_method:call(get__OtherItemDataList_method:call(MysteryLaboTradePointItemFacility), 14);
            end

            local MaxExchangeableNum = getMaxExchangeableNum_method:call(MysteryLaboTradePointItemFacility, PLATINUM_EGG_DATA);
            local ExchangeStatus = checkExchangeStatus_method:call(MysteryLaboTradePointItemFacility, PLATINUM_EGG_DATA, MaxExchangeableNum);

            if ExchangeStatus == 0 then
                exchange_method:call(MysteryLaboTradePointItemFacility, PLATINUM_EGG_DATA, MaxExchangeableNum);
            elseif ExchangeStatus == 2 then
                SendMessage("백금알 수량 MAX!");
            end
        end
    end
};
--
return this;