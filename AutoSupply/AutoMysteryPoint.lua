local Constants = _G.require("Constants.Constants");
--
local get_managed_singleton = Constants.sdk.get_managed_singleton;

local SendMessage = Constants.SendMessage;
local getCountOfAll = Constants.getCountOfAll;
--
local MysteryLaboTradePointItemFacility_type_def = Constants.sdk.find_type_definition("snow.facility.MysteryLaboTradePointItemFacility");
local get__AllTradeItemDataList_method = MysteryLaboTradePointItemFacility_type_def:get_method("get__AllTradeItemDataList");
local getMaxExchangeableNum_method = MysteryLaboTradePointItemFacility_type_def:get_method("getMaxExchangeableNum(snow.facility.mysteryLabo.MysteryLaboTradeItemData)");
local checkExchangeStatus_method = MysteryLaboTradePointItemFacility_type_def:get_method("checkExchangeStatus(snow.facility.mysteryLabo.MysteryLaboTradeItemData, System.UInt32)");
local exchange_method = MysteryLaboTradePointItemFacility_type_def:get_method("exchange(snow.facility.mysteryLabo.MysteryLaboTradeItemData, System.UInt32)");
--
local this = {
    exchange = function()
        if getCountOfAll(68160340) >= 9999 then
            local MysteryLaboTradePointItemFacility = get_managed_singleton("snow.facility.MysteryLaboTradePointItemFacility");
            local PLATINUM_EGG_DATA = get__AllTradeItemDataList_method:call(MysteryLaboTradePointItemFacility):get_element(93);
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