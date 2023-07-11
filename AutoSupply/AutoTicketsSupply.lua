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
local get_Kitchen_method = Constants.SDK.find_type_definition("snow.data.FacilityDataManager"):get_method("get_Kitchen");

local get_BbqFunc_method = get_Kitchen_method:get_return_type():get_method("get_BbqFunc");

local outputTicket_method = get_BbqFunc_method:get_return_type():get_method("outputTicket");
--
local NpcTalkMessageCtrl_type_def = Constants.SDK.find_type_definition("snow.npc.NpcTalkMessageCtrl");
local get_NpcId_method = NpcTalkMessageCtrl_type_def:get_method("get_NpcId");
local resetTalkDispName_method = NpcTalkMessageCtrl_type_def:get_method("resetTalkDispName");
local set_DetermineSpeechBalloonMessage_method = NpcTalkMessageCtrl_type_def:get_method("set_DetermineSpeechBalloonMessage(System.String)");
local set_SpeechBalloonAttr_method = NpcTalkMessageCtrl_type_def:get_method("set_SpeechBalloonAttr(snow.npc.TalkAttribute)");
local talkAction2_CommercialStuffItem_method = NpcTalkMessageCtrl_type_def:get_method("talkAction2_CommercialStuffItem(snow.NpcDefine.NpcID, snow.npc.TalkAction2Param, System.UInt32)");
local talkAction2_SupplyMysteryResearchRequestReward_method = NpcTalkMessageCtrl_type_def:get_method("talkAction2_SupplyMysteryResearchRequestReward(snow.NpcDefine.NpcID, snow.npc.TalkAction2Param, System.UInt32)");

local TalkAttribute_NONE = Constants.SDK.find_type_definition("snow.npc.TalkAttribute"):get_field("TALK_ATTR_NONE"):get_data(nil);

local NpcId_type_def = get_NpcId_method:get_return_type();
local npcList = {
    ["Bahari"] = NpcId_type_def:get_field("nid503"):get_data(nil),
    ["Pingarh"] = NpcId_type_def:get_field("nid715"):get_data(nil)
};
--
local isCommercialStuff = false;
local isMysteryResearchRequestClear = false;
local CommercialNpcTalkMessageCtrl = nil;
local MysteryLaboNpcTalkMessageCtrl = nil;

local NpcTalkMessageCtrl = nil;
local function PreHook_getTalkTarget(args)
    if isCommercialStuff == true or isMysteryResearchRequestClear == true then
        NpcTalkMessageCtrl = Constants.SDK.to_managed_object(args[2]);
    end
end
local function PostHook_getTalkTarget()
    if NpcTalkMessageCtrl == nil then
        return;
    end

    local NpcId = get_NpcId_method:call(NpcTalkMessageCtrl);
    if (isCommercialStuff == true and NpcId == npcList.Pingarh) then
        CommercialNpcTalkMessageCtrl = NpcTalkMessageCtrl;
    elseif (isMysteryResearchRequestClear == true and NpcId == npcList.Bahari) then
        MysteryLaboNpcTalkMessageCtrl = NpcTalkMessageCtrl;
    end

    NpcTalkMessageCtrl = nil;
end

local function talkHandler(retval)
    if CommercialNpcTalkMessageCtrl ~= nil and talkAction2_CommercialStuffItem_method:call(CommercialNpcTalkMessageCtrl, npcList.Pingarh, 0, 0) == true then
        isCommercialStuff = false;
        CommercialNpcTalkMessageCtrl = nil;
    end

    if MysteryLaboNpcTalkMessageCtrl ~= nil and talkAction2_SupplyMysteryResearchRequestReward_method:call(MysteryLaboNpcTalkMessageCtrl, npcList.Bahari, 0, 0) == true then
        isMysteryResearchRequestClear = false;
        resetTalkDispName_method:call(MysteryLaboNpcTalkMessageCtrl);
        set_DetermineSpeechBalloonMessage_method:call(MysteryLaboNpcTalkMessageCtrl, nil);
        set_SpeechBalloonAttr_method:call(MysteryLaboNpcTalkMessageCtrl, TalkAttribute_NONE);
        MysteryLaboNpcTalkMessageCtrl = nil;
    end

    return retval;
end

local function GetTicket(ticketType)
    local ProgressTicketSupplyManager = Constants.SDK.get_managed_singleton("snow.progress.ProgressTicketSupplyManager");
    if ProgressTicketSupplyManager ~= nil then
        Ticket_supply_method:call(ProgressTicketSupplyManager, ticketType);
    end
end

function this.init()
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("start"), PreHook_getTalkTarget, PostHook_getTalkTarget);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("onLoad"), PreHook_getTalkTarget, PostHook_getTalkTarget);
    Constants.SDK.hook(Constants.SDK.find_type_definition("snow.VillageMapManager"):get_method("getCurrentMapNo"), nil, talkHandler);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkPickItem_V02Ticket(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        if Constants.to_bool(retval) == true then
            GetTicket(TicketType.V02Ticket);
            return Constants.FALSE_POINTER;
        end
        return retval;
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkPickItem_MysteryTicket(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        if Constants.to_bool(retval) == true then
            GetTicket(TicketType.MysteryTicket);
            return Constants.FALSE_POINTER;
        end
        return retval;
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkPickItem_VillageTicket(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        if Constants.to_bool(retval) == true then
            GetTicket(TicketType.Village);
            return Constants.FALSE_POINTER;
        end
        return retval;
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkPickItem_GuildTicket(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        if Constants.to_bool(retval) == true then
            GetTicket(TicketType.Hall);
            return Constants.FALSE_POINTER;
        end
        return retval;
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkSupplyItem_OtomoTicket(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        if Constants.to_bool(retval) == true then
            local ProgressOtomoTicketManager = Constants.SDK.get_managed_singleton("snow.progress.ProgressOtomoTicketManager");
            if ProgressOtomoTicketManager ~= nil then
                Otomo_supply_method:call(ProgressOtomoTicketManager);
                return Constants.FALSE_POINTER;
            end
        end
        return retval;
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkSupplyItem_Ec019(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        if Constants.to_bool(retval) == true then
            local ProgressEc019UnlockItemManager = Constants.SDK.get_managed_singleton("snow.progress.ProgressEc019UnlockItemManager");
            if ProgressEc019UnlockItemManager ~= nil then
                Ec019_supply_method:call(ProgressEc019UnlockItemManager);
                return Constants.FALSE_POINTER;
            end
        end
        return retval;
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkSupplyItem_Ec019MR(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        if Constants.to_bool(retval) == true then
            local ProgressEc019UnlockItemManager = Constants.SDK.get_managed_singleton("snow.progress.ProgressEc019UnlockItemManager");
            if ProgressEc019UnlockItemManager ~= nil then
                Ec019_supplyMR_method:call(ProgressEc019UnlockItemManager);
                return Constants.FALSE_POINTER;
            end
        end
        return retval;
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkSwitchAction_EnableSupply_Smithy(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        if Constants.to_bool(retval) == true then
            local ProgressSwitchActionSupplyManager = Constants.SDK.get_managed_singleton("snow.progress.ProgressSwitchActionSupplyManager");
            if ProgressSwitchActionSupplyManager ~= nil then
                SwitchAction_supply_method:call(ProgressSwitchActionSupplyManager);
                return Constants.FALSE_POINTER;
            end
        end
        return retval;
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkSupplyItem_GoodReward(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        if Constants.to_bool(retval) == true then
            local ProgressGoodRewardManager = Constants.SDK.get_managed_singleton("snow.progress.ProgressGoodRewardManager");
            if ProgressGoodRewardManager ~= nil then
                supplyReward_method:call(ProgressGoodRewardManager);
                return Constants.FALSE_POINTER;
            end
        end
        return retval;
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkSupplyItem_BBQReward(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        if Constants.to_bool(retval) == true then
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
        if Constants.to_bool(retval) == true then
            local ProgressNoteRewardManager = Constants.SDK.get_managed_singleton("snow.progress.ProgressNoteRewardManager");
            if ProgressNoteRewardManager ~= nil then
                Note_supply_method:call(ProgressNoteRewardManager);
                return Constants.FALSE_POINTER;
            end
        end
        return retval;
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkNoteReward_SupplyAnyOrnament_MR(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        if Constants.to_bool(retval) == true then
            local ProgressNoteRewardManager = Constants.SDK.get_managed_singleton("snow.progress.ProgressNoteRewardManager");
            if ProgressNoteRewardManager ~= nil then
                Note_supply_method:call(ProgressNoteRewardManager);
                return Constants.FALSE_POINTER;
            end
        end
        return retval;
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkCommercialStuff(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        isCommercialStuff = Constants.to_bool(retval);
        return retval;
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkMysteryResearchRequestEnd(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        isMysteryResearchRequestClear = Constants.to_bool(retval);
        return retval;
    end);
end

return this;