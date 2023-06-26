local Constants = require("Constants.Constants");
if not Constants then
    return;
end
--
local this = {};
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
local ProgressEc019UnlockItemManager_type_def = Constants.SDK.find_type_definition("snow.progress.ProgressEc019UnlockItemManager");
local Ec019_supply_method = ProgressEc019UnlockItemManager_type_def:get_method("supply");
local Ec019_supplyMR_method = ProgressEc019UnlockItemManager_type_def:get_method("supplyMR");
--
local ProgressSwitchActionSupplyManager_type_def = Constants.SDK.find_type_definition("snow.progress.ProgressSwitchActionSupplyManager");
local SwitchAction_supply_method = ProgressSwitchActionSupplyManager_type_def:get_method("supply");
--
local ProgressNoteRewardManager_type_def = Constants.SDK.find_type_definition("snow.progress.ProgressNoteRewardManager");
local Note_supply_method = ProgressNoteRewardManager_type_def:get_method("supply");
--
local NpcTalkMessageCtrl_type_def = Constants.SDK.find_type_definition("snow.npc.NpcTalkMessageCtrl");
local get_NpcId_method = NpcTalkMessageCtrl_type_def:get_method("get_NpcId"); -- retval
local resetTalkDispName_method = NpcTalkMessageCtrl_type_def:get_method("resetTalkDispName");
local executeTalkAction_method = NpcTalkMessageCtrl_type_def:get_method("executeTalkAction");
local set_DetermineSpeechBalloonMessage_method = NpcTalkMessageCtrl_type_def:get_method("set_DetermineSpeechBalloonMessage(System.String)");
local set_SpeechBalloonAttr_method = NpcTalkMessageCtrl_type_def:get_method("set_SpeechBalloonAttr(snow.npc.TalkAttribute)");

local get_CurrentVillageNo_method = Constants.SDK.find_type_definition("snow.VillageAreaManager"):get_method("get_CurrentVillageNo");

local ELGADO = get_CurrentVillageNo_method:get_return_type():get_field("Village02"):get_data(nil);

local TalkAttribute_NONE = Constants.SDK.find_type_definition("snow.npc.TalkAttribute"):get_field("TALK_ATTR_NONE"):get_data(nil);

local NpcId_type_def = get_NpcId_method:get_return_type();
local Bahari_Id = NpcId_type_def:get_field("nid503"):get_data(nil);
local Pingarh_Id = NpcId_type_def:get_field("nid715"):get_data(nil);
--
local ctorObjList = nil;
local npcTalkMessageList = nil;

local function talkAction(npcTalkMessageCtrl, isCtorObj)
    if isCtorObj then
        npcTalkMessageCtrl:call("resetTalkDispName");
        npcTalkMessageCtrl:call("executeTalkAction");
        npcTalkMessageCtrl:call("set_DetermineSpeechBalloonMessage(System.String)", nil);
        npcTalkMessageCtrl:call("set_SpeechBalloonAttr(snow.npc.TalkAttribute)", TalkAttribute_NONE);
    else
        resetTalkDispName_method:call(npcTalkMessageCtrl);
        executeTalkAction_method:call(npcTalkMessageCtrl);
        set_DetermineSpeechBalloonMessage_method:call(npcTalkMessageCtrl, nil);
        set_SpeechBalloonAttr_method:call(npcTalkMessageCtrl, TalkAttribute_NONE);
    end
end

local ctorObj = nil;
local function PreHook_ctor(args)
    ctorObj = Constants.SDK.to_managed_object(args[2]);
end
local function PostHook_ctor()
    if ctorObj then
        if not ctorObjList then
            ctorObjList = {ctorObj};
        else
            Constants.LUA.table_insert(ctorObjList, ctorObj);
        end
    end
    ctorObj = nil;
end

local NpcTalkMessageCtrl = nil;
local function PreHook_getTalkTarget(args)
    NpcTalkMessageCtrl = Constants.SDK.to_managed_object(args[2]);
end
local function PostHook_getTalkTarget()
    if NpcTalkMessageCtrl then
        local NpcId = get_NpcId_method:call(NpcTalkMessageCtrl);
        if NpcId == Pingarh_Id or NpcId == Bahari_Id then
            if not npcTalkMessageList then
                npcTalkMessageList = {NpcTalkMessageCtrl};
            else
                Constants.LUA.table_insert(npcTalkMessageList, NpcTalkMessageCtrl);
            end
        end
    end
    NpcTalkMessageCtrl = nil;
end

local function PostHook_getCurrentMapNo(retval)
    if ctorObjList or npcTalkMessageList then
        local VillageAreaManager = Constants.SDK.get_managed_singleton("snow.VillageAreaManager");
        if VillageAreaManager and get_CurrentVillageNo_method:call(VillageAreaManager) == ELGADO then
            if ctorObjList then
                for _, v in Constants.LUA.pairs(ctorObjList) do
                    if v ~= nil and Constants.SDK.is_managed_object(v) then
                        local NpcId = v:call("get_NpcId");
                        if NpcId == Pingarh_Id or NpcId == Bahari_Id then
                            talkAction(v, true);
                        end
                    end
                end
            end
            if npcTalkMessageList then
                for _, v in Constants.LUA.pairs(npcTalkMessageList) do
                    if v ~= nil and Constants.SDK.is_managed_object(v) then
                        talkAction(v, false);
                    end
                end
            end
            ctorObjList = nil;
            npcTalkMessageList = nil;
        end
    end
    return retval;
end

local ProgressGoodRewardManager = nil;
local function PreHook_checkReward(args)
    ProgressGoodRewardManager = Constants.SDK.to_managed_object(args[2]);
end
local function PostHook_checkReward(retval)
    if ProgressGoodRewardManager and (Constants.SDK.to_int64(retval) & 1) == 1 then
        --local VillageAreaManager = Constants.SDK.get_managed_singleton("snow.VillageAreaManager");
        --if VillageAreaManager and get_CurrentVillageNo_method:call(VillageAreaManager) == ELGADO then
            supplyReward_method:call(ProgressGoodRewardManager);
            ProgressGoodRewardManager = nil;
            return Constants.FALSE_POINTER;
        --end
    end
    ProgressGoodRewardManager = nil;
    return retval;
end

local ProgressOtomoTicketManager = nil;
local function PreHook_isSupplyItem(args)
    ProgressOtomoTicketManager = Constants.SDK.to_managed_object(args[2]);
end
local function PostHook_isSupplyItem(retval)
    if ProgressOtomoTicketManager and (Constants.SDK.to_int64(retval) & 1) == 1 then
        Otomo_supply_method:call(ProgressOtomoTicketManager);
        ProgressOtomoTicketManager = nil;
        return Constants.FALSE_POINTER;
    end
    ProgressOtomoTicketManager = nil;
    return retval;
end

local ProgressTicketSupplyManager = nil;
local ticketType = nil;
local function PreHook_isEnableSupply(args)
    ProgressTicketSupplyManager = Constants.SDK.to_managed_object(args[2]);
    ticketType = Constants.SDK.to_int64(args[3]);
end
local function PostHook_isEnableSupply(retval)
    if ProgressTicketSupplyManager and ticketType ~= nil and (Constants.SDK.to_int64(retval) & 1) == 1 then
        Ticket_supply_method:call(ProgressTicketSupplyManager, ticketType);
        ProgressTicketSupplyManager = nil;
        ticketType = nil;
        return Constants.FALSE_POINTER;
    end
    ProgressTicketSupplyManager = nil;
    ticketType = nil;
    return retval;
end

local ProgressEc019UnlockItemManager = nil;
local function PreHook_Ec019_isSupply(args)
    ProgressEc019UnlockItemManager = Constants.SDK.to_managed_object(args[2]);
end
local function PostHook_Ec019_isSupply(retval)
    if ProgressEc019UnlockItemManager and (Constants.SDK.to_int64(retval) & 1) == 1 then
        Ec019_supply_method:call(ProgressEc019UnlockItemManager);
        ProgressEc019UnlockItemManager = nil;
        return Constants.FALSE_POINTER;
    end
    ProgressEc019UnlockItemManager = nil;
    return retval;
end
local function PostHook_Ec019_isSupplyMR(retval)
    if ProgressEc019UnlockItemManager and (Constants.SDK.to_int64(retval) & 1) == 1 then
        Ec019_supplyMR_method:call(ProgressEc019UnlockItemManager);
        ProgressEc019UnlockItemManager = nil;
        return Constants.FALSE_POINTER;
    end
    ProgressEc019UnlockItemManager = nil;
    return retval;
end

local ProgressSwitchActionSupplyManager = nil;
local function PreHook_SwitchAction_isEnableSupply(args)
    ProgressSwitchActionSupplyManager = Constants.SDK.to_managed_object(args[2]);
end
local function PostHook_SwitchAction_isEnableSupply(retval)
    if ProgressSwitchActionSupplyManager and (Constants.SDK.to_int64(retval) & 1) == 1 then
        SwitchAction_supply_method:call(ProgressSwitchActionSupplyManager);
        ProgressSwitchActionSupplyManager = nil;
        return Constants.FALSE_POINTER;
    end
    ProgressSwitchActionSupplyManager = nil;
    return retval;
end

local ProgressNoteRewardManager = nil;
local function PreHook_checkSupplyAnyFigurine(args)
    ProgressNoteRewardManager = Constants.SDK.to_managed_object(args[2]);
end
local function PostHook_checkSupplyAnyFigurine(retval)
    if ProgressNoteRewardManager and (Constants.SDK.to_int64(retval) & 1) == 1 then
        Note_supply_method:call(ProgressNoteRewardManager);
        ProgressNoteRewardManager = nil;
        return Constants.FALSE_POINTER;
    end
    ProgressNoteRewardManager = nil;
    return retval;
end

function this.init()
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method(".ctor"), PreHook_ctor, PostHook_ctor);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("start"), PreHook_getTalkTarget, PostHook_getTalkTarget);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("onLoad"), PreHook_getTalkTarget, PostHook_getTalkTarget);
    Constants.SDK.hook(Constants.SDK.find_type_definition("snow.VillageMapManager"):get_method("getCurrentMapNo"), nil, PostHook_getCurrentMapNo);
    Constants.SDK.hook(ProgressGoodRewardManager_type_def:get_method("checkReward"), PreHook_checkReward, PostHook_checkReward);
    Constants.SDK.hook(ProgressOtomoTicketManager_type_def:get_method("isSupplyItem"), PreHook_isSupplyItem, PostHook_isSupplyItem);
    Constants.SDK.hook(ProgressTicketSupplyManager_type_def:get_method("isEnableSupply(snow.progress.ProgressTicketSupplyManager.TicketType)"), PreHook_isEnableSupply, PostHook_isEnableSupply);
    Constants.SDK.hook(ProgressEc019UnlockItemManager_type_def:get_method("isSupply"), PreHook_Ec019_isSupply, PostHook_Ec019_isSupply);
    Constants.SDK.hook(ProgressEc019UnlockItemManager_type_def:get_method("isSupplyMR"), PreHook_Ec019_isSupply, PostHook_Ec019_isSupplyMR);
    Constants.SDK.hook(ProgressSwitchActionSupplyManager_type_def:get_method("isEnableSupply"), PreHook_SwitchAction_isEnableSupply, PostHook_SwitchAction_isEnableSupply);
    Constants.SDK.hook(ProgressNoteRewardManager_type_def:get_method("checkSupplyAnyFigurine"), PreHook_checkSupplyAnyFigurine, PostHook_checkSupplyAnyFigurine);
    Constants.SDK.hook(ProgressNoteRewardManager_type_def:get_method("checkSupplyAnyFigurine_MR"), PreHook_checkSupplyAnyFigurine, PostHook_checkSupplyAnyFigurine);
end

return this;