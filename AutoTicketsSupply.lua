local Constants = require("Constants.Constants");
if not Constants then
    return;
end
--
local ProgressGoodRewardManager_type_def = Constants.SDK.find_type_definition("snow.progress.ProgressGoodRewardManager");
local supplyReward_method = ProgressGoodRewardManager_type_def:get_method("supplyReward");
--
local ProgressOtomoTicketManager_type_def = Constants.SDK.find_type_definition("snow.progress.ProgressOtomoTicketManager");
local Otomo_supply_method = ProgressOtomoTicketManager_type_def:get_method("supply");
--
local ProgressTicketSupplyManager_type_def = Constants.SDK.find_type_definition("snow.progress.ProgressTicketSupplyManager");
local Ticket_supply_method = ProgressTicketSupplyManager_type_def:get_method("supply(snow.progress.ProgressTicketSupplyManager.TicketType)");
--
local ProgressGoodRewardManager = nil;
Constants.SDK.hook(ProgressGoodRewardManager_type_def:get_method("checkReward"), function(args)
    ProgressGoodRewardManager = Constants.SDK.to_managed_object(args[2]);
end, function(retval)
    if ProgressGoodRewardManager and (Constants.SDK.to_int64(retval) & 1) == 1 then
        supplyReward_method:call(ProgressGoodRewardManager);
        ProgressGoodRewardManager = nil;
        return Constants.FALSE_POINTER;
    end
    ProgressGoodRewardManager = nil;
    return retval;
end);

local ProgressOtomoTicketManager = nil;
Constants.SDK.hook(ProgressOtomoTicketManager_type_def:get_method("isSupplyItem"), function(args)
    ProgressOtomoTicketManager = Constants.SDK.to_managed_object(args[2]);
end, function(retval)
    if ProgressOtomoTicketManager and (Constants.SDK.to_int64(retval) & 1) == 1 then
        Otomo_supply_method:call(ProgressOtomoTicketManager);
        ProgressOtomoTicketManager = nil;
        return Constants.FALSE_POINTER;
    end
    ProgressOtomoTicketManager = nil;
    return retval;
end);

local ProgressTicketSupplyManager = nil;
local ticketType = nil;
Constants.SDK.hook(ProgressTicketSupplyManager_type_def:get_method("isEnableSupply(snow.progress.ProgressTicketSupplyManager.TicketType)"), function(args)
    ProgressTicketSupplyManager = Constants.SDK.to_managed_object(args[2]);
    ticketType = Constants.SDK.to_int64(args[3]);
end, function(retval)
    if ProgressTicketSupplyManager and ticketType ~= nil and (Constants.SDK.to_int64(retval) & 1) == 1 then
        Ticket_supply_method:call(ProgressTicketSupplyManager, ticketType);
        ProgressTicketSupplyManager = nil;
        ticketType = nil;
        return Constants.FALSE_POINTER;
    end
    ProgressTicketSupplyManager = nil;
    ticketType = nil;
    return retval;
end);