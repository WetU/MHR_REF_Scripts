local Constants = require("Constants.Constants");
if not Constants then
    return;
end
--
local this = {};
--
local supplyReward_method = Constants.SDK.find_type_definition("snow.progress.ProgressGoodRewardManager"):get_method("supplyReward");
--
local Otomo_supply_method = Constants.SDK.find_type_definition("snow.progress.ProgressOtomoTicketManager"):get_method("supply");
--
local Ticket_supply_method = Constants.SDK.find_type_definition("snow.progress.ProgressTicketSupplyManager"):get_method("supply(snow.progress.ProgressTicketSupplyManager.TicketType)");

local TicketType_type_def = Constants.SDK.find_type_definition("snow.progress.ProgressTicketSupplyManager.TicketType");
local TicketType = {
    Village = TicketType_type_def:get_field("Village"):get_data(nil),
    Hall = TicketType_type_def:get_field("Hall"):get_data(nil),
    V02Ticket = TicketType_type_def:get_field("V02Ticket"):get_data(nil),
    MysteryTicket = TicketType_type_def:get_field("MysteryTicket"):get_data(nil)
};
--
local ProgressEc019UnlockItemManager_type_def = Constants.SDK.find_type_definition("snow.progress.ProgressEc019UnlockItemManager");
local Ec019_supply_method = ProgressEc019UnlockItemManager_type_def:get_method("supply");
local Ec019_supplyMR_method = ProgressEc019UnlockItemManager_type_def:get_method("supplyMR");
--
local SwitchAction_supply_method = Constants.SDK.find_type_definition("snow.progress.ProgressSwitchActionSupplyManager"):get_method("supply");
--
local Note_supply_method = Constants.SDK.find_type_definition("snow.progress.ProgressNoteRewardManager"):get_method("supply");
--
local FacilityDataManager_type_def = Constants.SDK.find_type_definition("snow.data.FacilityDataManager");
local get_Kitchen_method = FacilityDataManager_type_def:get_method("get_Kitchen");

local get_BbqFunc_method = get_Kitchen_method:get_return_type():get_method("get_BbqFunc");

local outputTicket_method = get_BbqFunc_method:get_return_type():get_method("outputTicket");
--
local getCommercialStuffFacility_method = FacilityDataManager_type_def:get_method("getCommercialStuffFacility");

local CommercialStuffFacility_type_def = getCommercialStuffFacility_method:get_return_type();
local get_CommercialStuffID_method = CommercialStuffFacility_type_def:get_method("get_CommercialStuffID");
local get_CanObtainlItem_method = CommercialStuffFacility_type_def:get_method("get_CanObtainlItem");

local CommercialStuff_None = get_CommercialStuffID_method:get_return_type():get_field("CommercialStuff_None"):get_data(nil);
--
local getMysteryLaboFacility_method = FacilityDataManager_type_def:get_method("getMysteryLaboFacility");

local get_LaboReward_method = getMysteryLaboFacility_method:get_return_type():get_method("get_LaboReward");

local get_IsClear_method = get_LaboReward_method:get_return_type():get_method("get_IsClear");
--
local NpcTalkMessageCtrl_type_def = Constants.SDK.find_type_definition("snow.npc.NpcTalkMessageCtrl");
local get_NpcId_method = NpcTalkMessageCtrl_type_def:get_method("get_NpcId");
local talkAction2_CommercialStuffItem_method = NpcTalkMessageCtrl_type_def:get_method("talkAction2_CommercialStuffItem(snow.NpcDefine.NpcID, snow.npc.TalkAction2Param, System.UInt32)");
local talkAction2_SupplyMysteryResearchRequestReward_method = NpcTalkMessageCtrl_type_def:get_method("talkAction2_SupplyMysteryResearchRequestReward(snow.NpcDefine.NpcID, snow.npc.TalkAction2Param, System.UInt32)");

local NpcId_type_def = get_NpcId_method:get_return_type();
local npcList = {
    --[[["KAMURA"] = {
        ["Fugen"] = NpcId_type_def:get_field("nid001"):get_data(nil),
        ["Kagero"] = NpcId_type_def:get_field("nid003"):get_data(nil),
        ["Yomogi"] = NpcId_type_def:get_field("nid004"):get_data(nil),
        ["Hojo"] = NpcId_type_def:get_field("nid101"):get_data(nil),
        ["Iori"] = NpcId_type_def:get_field("nid302"):get_data(nil)
    },]]
    ["ELGADO"] = {
        --["Gallues"] = NpcId_type_def:get_field("nid502"):get_data(nil),
        ["Bahari"] = NpcId_type_def:get_field("nid503"):get_data(nil),
        --["Nagi"] = NpcId_type_def:get_field("nid606"):get_data(nil),
        --["Oboro"] = NpcId_type_def:get_field("nid607"):get_data(nil),
        --["Azuki"] = NpcId_type_def:get_field("nid608"):get_data(nil),
        ["Pingarh"] = NpcId_type_def:get_field("nid715"):get_data(nil)
    }
};
--
local function GetTicket(retval, ticketType)
    if (Constants.SDK.to_int64(retval) & 1) == 1 then
        local ProgressTicketSupplyManager = Constants.SDK.get_managed_singleton("snow.progress.ProgressTicketSupplyManager");
        if ProgressTicketSupplyManager ~= nil then
            Ticket_supply_method:call(ProgressTicketSupplyManager, ticketType);
            return Constants.FALSE_POINTER;
        end
    end
    return retval;
end

local NpcTalkMessageCtrl = nil;
local function PreHook_getTalkTarget(args)
    NpcTalkMessageCtrl = Constants.SDK.to_managed_object(args[2]);
end
local function PostHook_getTalkTarget()
    if NpcTalkMessageCtrl == nil then
        return;
    end

    local NpcId = get_NpcId_method:call(NpcTalkMessageCtrl);
    if NpcId == npcList.ELGADO.Pingarh then
        local FacilityDataManager = Constants.SDK.get_managed_singleton("snow.data.FacilityDataManager");
        if FacilityDataManager ~= nil then
            local CommercialStuffFacility = getCommercialStuffFacility_method:call(FacilityDataManager);
            if CommercialStuffFacility ~= nil and get_CommercialStuffID_method:call(CommercialStuffFacility) ~= CommercialStuff_None and get_CanObtainlItem_method:call(CommercialStuffFacility) == true then
                talkAction2_CommercialStuffItem_method:call(NpcTalkMessageCtrl, NpcId, 0, 0);
            end
        end
    elseif NpcId == npcList.ELGADO.Bahari then
        local FacilityDataManager = Constants.SDK.get_managed_singleton("snow.data.FacilityDataManager");
        if FacilityDataManager ~= nil then
            local MysteryLaboFacility = getMysteryLaboFacility_method:call(FacilityDataManager);
            if MysteryLaboFacility ~= nil then
                local MysteryLaboReward = get_LaboReward_method:call(MysteryLaboFacility);
                if MysteryLaboReward ~= nil and get_IsClear_method:call(MysteryLaboReward) == true then
                    talkAction2_SupplyMysteryResearchRequestReward_method:call(NpcTalkMessageCtrl, NpcId, 0, 0);
                end
            end
        end
    end

    NpcTalkMessageCtrl = nil;
end

function this.init()
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("start"), PreHook_getTalkTarget, PostHook_getTalkTarget);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("onLoad"), PreHook_getTalkTarget, PostHook_getTalkTarget);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkPickItem_V02Ticket(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        return GetTicket(retval, TicketType.V02Ticket);
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkPickItem_MysteryTicket(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        return GetTicket(retval, TicketType.MysteryTicket);
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkPickItem_VillageTicket(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        return GetTicket(retval, TicketType.Village);
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkPickItem_GuildTicket(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        return GetTicket(retval, TicketType.Hall);
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkSupplyItem_OtomoTicket(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        if (Constants.SDK.to_int64(retval) & 1) == 1 then
            local ProgressOtomoTicketManager = Constants.SDK.get_managed_singleton("snow.progress.ProgressOtomoTicketManager");
            if ProgressOtomoTicketManager ~= nil then
                Otomo_supply_method:call(ProgressOtomoTicketManager);
                return Constants.FALSE_POINTER;
            end
        end
        return retval;
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkSupplyItem_Ec019(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        if (Constants.SDK.to_int64(retval) & 1) == 1 then
            local ProgressEc019UnlockItemManager = Constants.SDK.get_managed_singleton("snow.progress.ProgressEc019UnlockItemManager");
            if ProgressEc019UnlockItemManager ~= nil then
                Ec019_supply_method:call(ProgressEc019UnlockItemManager);
                return Constants.FALSE_POINTER;
            end
        end
        return retval;
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkSupplyItem_Ec019MR(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        if (Constants.SDK.to_int64(retval) & 1) == 1 then
            local ProgressEc019UnlockItemManager = Constants.SDK.get_managed_singleton("snow.progress.ProgressEc019UnlockItemManager");
            if ProgressEc019UnlockItemManager ~= nil then
                Ec019_supplyMR_method:call(ProgressEc019UnlockItemManager);
                return Constants.FALSE_POINTER;
            end
        end
        return retval;
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkSwitchAction_EnableSupply_Smithy(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        if (Constants.SDK.to_int64(retval) & 1) == 1 then
            local ProgressSwitchActionSupplyManager = Constants.SDK.get_managed_singleton("snow.progress.ProgressSwitchActionSupplyManager");
            if ProgressSwitchActionSupplyManager ~= nil then
                SwitchAction_supply_method:call(ProgressSwitchActionSupplyManager);
                return Constants.FALSE_POINTER;
            end
        end
        return retval;
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkSupplyItem_GoodReward(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        if (Constants.SDK.to_int64(retval) & 1) == 1 then
            local ProgressGoodRewardManager = Constants.SDK.get_managed_singleton("snow.progress.ProgressGoodRewardManager");
            if ProgressGoodRewardManager ~= nil then
                supplyReward_method:call(ProgressGoodRewardManager);
                return Constants.FALSE_POINTER;
            end
        end
        return retval;
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkSupplyItem_BBQReward(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        if (Constants.SDK.to_int64(retval) & 1) == 1 then
            local FacilityDataManager = Constants.SDK.get_managed_singleton("snow.data.FacilityDataManager");
            if FacilityDataManager ~= nil then
                local Kitchen = get_Kitchen_method:call(FacilityDataManager);
                if Kitchen ~= nil then
                    local BbqFunc = get_BbqFunc_method:call(Kitchen);
                    if BbqFunc ~= nil then
                        outputTicket_method:call(BbqFunc);
                        return Constants.FALSE_POINTER;
                    end
                end
            end
        end
        return retval;
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkNoteReward_SupplyAnyOrnament(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        if (Constants.SDK.to_int64(retval) & 1) == 1 then
            local ProgressNoteRewardManager = Constants.SDK.get_managed_singleton("snow.progress.ProgressNoteRewardManager");
            if ProgressNoteRewardManager ~= nil then
                Note_supply_method:call(ProgressNoteRewardManager);
                return Constants.FALSE_POINTER;
            end
        end
        return retval;
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkNoteReward_SupplyAnyOrnament_MR(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        if (Constants.SDK.to_int64(retval) & 1) == 1 then
            local ProgressNoteRewardManager = Constants.SDK.get_managed_singleton("snow.progress.ProgressNoteRewardManager");
            if ProgressNoteRewardManager ~= nil then
                Note_supply_method:call(ProgressNoteRewardManager);
                return Constants.FALSE_POINTER;
            end
        end
        return retval;
    end);
end

return this;