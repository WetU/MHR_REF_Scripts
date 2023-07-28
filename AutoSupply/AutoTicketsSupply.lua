local Constants = require("Constants.Constants");
--
local this = {};
--
local supplyReward_method = Constants.SDK.find_type_definition("snow.progress.ProgressGoodRewardManager"):get_method("supplyReward");
--
local Otomo_supply_method = Constants.SDK.find_type_definition("snow.progress.ProgressOtomoTicketManager"):get_method("supply");
--
local TicketType_type_def = Constants.SDK.find_type_definition("snow.progress.ProgressTicketSupplyManager.TicketType");
local TicketType = {
    Village = TicketType_type_def:get_field("Village"):get_data(nil),
    Hall = TicketType_type_def:get_field("Hall"):get_data(nil),
    V02Ticket = TicketType_type_def:get_field("V02Ticket"):get_data(nil),
    MysteryTicket = TicketType_type_def:get_field("MysteryTicket"):get_data(nil)
};
local Ticket_supply_method = Constants.SDK.find_type_definition("snow.progress.ProgressTicketSupplyManager"):get_method("supply(snow.progress.ProgressTicketSupplyManager.TicketType)");
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
local getMysteryLaboFacility_method = FacilityDataManager_type_def:get_method("getMysteryLaboFacility");

local get_LaboReward_method = getMysteryLaboFacility_method:get_return_type():get_method("get_LaboReward");

local get_IsClear_method = get_LaboReward_method:get_return_type():get_method("get_IsClear");
--
local getCommercialStuffFacility_method = FacilityDataManager_type_def:get_method("getCommercialStuffFacility");

local CommercialStuffFacility_type_def = getCommercialStuffFacility_method:get_return_type();
local get_CommercialStuffID_method = CommercialStuffFacility_type_def:get_method("get_CommercialStuffID");
local get_CanObtainlItem_method = CommercialStuffFacility_type_def:get_method("get_CanObtainlItem");

local CommercialStuff_None = get_CommercialStuffID_method:get_return_type():get_field("CommercialStuff_None"):get_data(nil);
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
local MysteryResearchRequestEnd = nil;
local CommercialStuff = nil;

local function get_CanObtainCommercialStuff()
    if CommercialStuff ~= nil then
        local result = CommercialStuff;
        CommercialStuff = nil;
        return result;
    end

    local CommercialStuffFacility = getCommercialStuffFacility_method:call(Constants.SDK.get_managed_singleton("snow.data.FacilityDataManager"));
    return get_CanObtainlItem_method:call(CommercialStuffFacility) == true and get_CommercialStuffID_method:call(CommercialStuffFacility) ~= CommercialStuff_None or nil;
end

local function get_IsMysteryResearchRequestClear()
    if MysteryResearchRequestEnd ~= nil then
        local result = MysteryResearchRequestEnd;
        MysteryResearchRequestEnd = nil;
        return result;
    end

    return get_IsClear_method:call(get_LaboReward_method:call(getMysteryLaboFacility_method:call(Constants.SDK.get_managed_singleton("snow.data.FacilityDataManager"))));
end
--
local function GetTicket(ticketType)
    Ticket_supply_method:call(Constants.SDK.get_managed_singleton("snow.progress.ProgressTicketSupplyManager"), ticketType);
    return Constants.FALSE_POINTER;
end

local function getNoteReward(retval)
    if Constants.to_bool(retval) == true then
        Note_supply_method:call(Constants.SDK.get_managed_singleton("snow.progress.ProgressNoteRewardManager"));
        return Constants.FALSE_POINTER;
    end

    return retval;
end
--
local CommercialNpcTalkMessageCtrl = nil;
local MysteryLaboNpcTalkMessageCtrl = nil;

local NpcTalkMessageCtrl = nil;
local function PreHook_getTalkTarget(args)
    NpcTalkMessageCtrl = Constants.SDK.to_managed_object(args[2]);
end
local function PostHook_getTalkTarget()
    local NpcId = get_NpcId_method:call(NpcTalkMessageCtrl);
    if NpcId == npcList.Pingarh and get_CanObtainCommercialStuff() == true then
        CommercialNpcTalkMessageCtrl = NpcTalkMessageCtrl;
    elseif NpcId == npcList.Bahari and get_IsMysteryResearchRequestClear() == true then
        MysteryLaboNpcTalkMessageCtrl = NpcTalkMessageCtrl;
    end

    NpcTalkMessageCtrl = nil;
end

function this.talkHandler()
    if CommercialNpcTalkMessageCtrl ~= nil and talkAction2_CommercialStuffItem_method:call(CommercialNpcTalkMessageCtrl, npcList.Pingarh, 0, 0) == true then
        CommercialNpcTalkMessageCtrl = nil;
    end

    if MysteryLaboNpcTalkMessageCtrl ~= nil and talkAction2_SupplyMysteryResearchRequestReward_method:call(MysteryLaboNpcTalkMessageCtrl, npcList.Bahari, 0, 0) == true then
        resetTalkDispName_method:call(MysteryLaboNpcTalkMessageCtrl);
        set_DetermineSpeechBalloonMessage_method:call(MysteryLaboNpcTalkMessageCtrl, nil);
        set_SpeechBalloonAttr_method:call(MysteryLaboNpcTalkMessageCtrl, TalkAttribute_NONE);
        MysteryLaboNpcTalkMessageCtrl = nil;
    end
end

function this.init()
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("start"), PreHook_getTalkTarget, PostHook_getTalkTarget);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("onLoad"), PreHook_getTalkTarget, PostHook_getTalkTarget);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkPickItem_V02Ticket(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        if Constants.to_bool(retval) == true then
            GetTicket(TicketType.V02Ticket);
        end

        return retval;
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkPickItem_MysteryTicket(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        if Constants.to_bool(retval) == true then
            GetTicket(TicketType.MysteryTicket);
        end

        return retval;
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkPickItem_VillageTicket(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        if Constants.to_bool(retval) == true then
            GetTicket(TicketType.Village);
        end

        return retval;
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkPickItem_GuildTicket(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        if Constants.to_bool(retval) == true then
            GetTicket(TicketType.Hall);
        end

        return retval;
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkSupplyItem_OtomoTicket(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        if Constants.to_bool(retval) == true then
            Otomo_supply_method:call(Constants.SDK.get_managed_singleton("snow.progress.ProgressOtomoTicketManager"));
            return Constants.FALSE_POINTER;
        end

        return retval;
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkSupplyItem_Ec019(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        if Constants.to_bool(retval) == true then
            Ec019_supply_method:call(Constants.SDK.get_managed_singleton("snow.progress.ProgressEc019UnlockItemManager"));
            return Constants.FALSE_POINTER;
        end

        return retval;
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkSupplyItem_Ec019MR(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        if Constants.to_bool(retval) == true then
            Ec019_supplyMR_method:call(Constants.SDK.get_managed_singleton("snow.progress.ProgressEc019UnlockItemManager"));
            return Constants.FALSE_POINTER;
        end

        return retval;
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkSwitchAction_EnableSupply_Smithy(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        if Constants.to_bool(retval) == true then
            SwitchAction_supply_method:call(Constants.SDK.get_managed_singleton("snow.progress.ProgressSwitchActionSupplyManager"));
            return Constants.FALSE_POINTER;
        end

        return retval;
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkSupplyItem_GoodReward(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        if Constants.to_bool(retval) == true then
            supplyReward_method:call(Constants.SDK.get_managed_singleton("snow.progress.ProgressGoodRewardManager"));
            return Constants.FALSE_POINTER;
        end

        return retval;
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkSupplyItem_BBQReward(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        if Constants.to_bool(retval) == true then
            outputTicket_method:call(get_BbqFunc_method:call(get_Kitchen_method:call(Constants.SDK.get_managed_singleton("snow.data.FacilityDataManager"))));
            return Constants.FALSE_POINTER;
        end

        return retval;
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkNoteReward_SupplyAnyOrnament(snow.npc.message.define.NpcMessageTalkTag)"), nil, getNoteReward);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkNoteReward_SupplyAnyOrnament_MR(snow.npc.message.define.NpcMessageTalkTag)"), nil, getNoteReward);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkMysteryResearchRequestEnd(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        if MysteryLaboNpcTalkMessageCtrl ~= nil and talkAction2_SupplyMysteryResearchRequestReward_method:call(MysteryLaboNpcTalkMessageCtrl, npcList.Bahari, 0, 0) == true then
            MysteryResearchRequestEnd = false;
            resetTalkDispName_method:call(MysteryLaboNpcTalkMessageCtrl);
            set_DetermineSpeechBalloonMessage_method:call(MysteryLaboNpcTalkMessageCtrl, nil);
            set_SpeechBalloonAttr_method:call(MysteryLaboNpcTalkMessageCtrl, TalkAttribute_NONE);
            MysteryLaboNpcTalkMessageCtrl = nil;
            return Constants.FALSE_POINTER;
        end

        MysteryResearchRequestEnd = Constants.to_bool(retval);
        return retval;
    end);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("checkCommercialStuff(snow.npc.message.define.NpcMessageTalkTag)"), nil, function(retval)
        CommercialStuff = Constants.to_bool(retval);
        return retval;
    end);
end

return this;