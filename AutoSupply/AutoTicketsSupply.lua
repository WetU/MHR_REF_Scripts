local Constants = require("Constants.Constants");
if not Constants then
    return;
end
--
local this = {};
--
local ProgressGoodRewardManager_type_def = Constants.SDK.find_type_definition("snow.progress.ProgressGoodRewardManager");
local checkReward_method = ProgressGoodRewardManager_type_def:get_method("checkReward");
local supplyReward_method = ProgressGoodRewardManager_type_def:get_method("supplyReward");
--
local ProgressOtomoTicketManager_type_def = Constants.SDK.find_type_definition("snow.progress.ProgressOtomoTicketManager");
local isSupplyItem_method = ProgressOtomoTicketManager_type_def:get_method("isSupplyItem");
local Otomo_supply_method = ProgressOtomoTicketManager_type_def:get_method("supply");
--
local ProgressTicketSupplyManager_type_def = Constants.SDK.find_type_definition("snow.progress.ProgressTicketSupplyManager");
local Ticket_isEnableSupply_method = ProgressTicketSupplyManager_type_def:get_method("isEnableSupply(snow.progress.ProgressTicketSupplyManager.TicketType)");
local Ticket_supply_method = ProgressTicketSupplyManager_type_def:get_method("supply(snow.progress.ProgressTicketSupplyManager.TicketType)");

local TicketType_type_def = Constants.SDK.find_type_definition("snow.progress.ProgressTicketSupplyManager.TicketType");
local TicketType = {
    TicketType_type_def:get_field("Village"):get_data(nil),
    TicketType_type_def:get_field("Hall"):get_data(nil),
    TicketType_type_def:get_field("V02Ticket"):get_data(nil),
    TicketType_type_def:get_field("MysteryTicket"):get_data(nil)
};
--
local ProgressEc019UnlockItemManager_type_def = Constants.SDK.find_type_definition("snow.progress.ProgressEc019UnlockItemManager");
local isSupply_method = ProgressEc019UnlockItemManager_type_def:get_method("isSupply");
local Ec019_supply_method = ProgressEc019UnlockItemManager_type_def:get_method("supply");
local isSupplyMR_method = ProgressEc019UnlockItemManager_type_def:get_method("isSupplyMR");
local Ec019_supplyMR_method = ProgressEc019UnlockItemManager_type_def:get_method("supplyMR");
--
local ProgressSwitchActionSupplyManager_type_def = Constants.SDK.find_type_definition("snow.progress.ProgressSwitchActionSupplyManager");
local SwitchAction_isEnableSupply_method = ProgressSwitchActionSupplyManager_type_def:get_method("isEnableSupply");
local SwitchAction_supply_method = ProgressSwitchActionSupplyManager_type_def:get_method("supply");
--
local ProgressNoteRewardManager_type_def = Constants.SDK.find_type_definition("snow.progress.ProgressNoteRewardManager");
local checkSupplyAnyFigurine_method = ProgressNoteRewardManager_type_def:get_method("checkSupplyAnyFigurine");
local checkSupplyAnyFigurine_MR_method = ProgressNoteRewardManager_type_def:get_method("checkSupplyAnyFigurine_MR");
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

function this.Supply()
    local ProgressGoodRewardManager = Constants.SDK.get_managed_singleton("snow.progress.ProgressGoodRewardManager");
    if ProgressGoodRewardManager ~= nil and checkReward_method:call(ProgressGoodRewardManager) == true then
        supplyReward_method:call(ProgressGoodRewardManager);
    end

    local ProgressOtomoTicketManager = Constants.SDK.get_managed_singleton("snow.progress.ProgressOtomoTicketManager");
    if ProgressOtomoTicketManager ~= nil and isSupplyItem_method:call(ProgressOtomoTicketManager) == true then
        Otomo_supply_method:call(ProgressOtomoTicketManager);
    end

    local ProgressTicketSupplyManager = Constants.SDK.get_managed_singleton("snow.progress.ProgressTicketSupplyManager");
    if ProgressTicketSupplyManager ~= nil then
        for _, v in ipairs(TicketType) do
            if Ticket_isEnableSupply_method:call(ProgressTicketSupplyManager, v) == true then
                Ticket_supply_method:call(ProgressTicketSupplyManager, v);
            end
        end
    end

    local ProgressEc019UnlockItemManager = Constants.SDK.get_managed_singleton("snow.progress.ProgressEc019UnlockItemManager");
    if ProgressEc019UnlockItemManager ~= nil then
        if isSupply_method:call(ProgressEc019UnlockItemManager) == true then
            Ec019_supply_method:call(ProgressEc019UnlockItemManager);
        end
        if isSupplyMR_method:call(ProgressEc019UnlockItemManager) == true then
            Ec019_supplyMR_method:call(ProgressEc019UnlockItemManager);
        end
    end

    local ProgressSwitchActionSupplyManager = Constants.SDK.get_managed_singleton("snow.progress.ProgressSwitchActionSupplyManager");
    if ProgressSwitchActionSupplyManager ~= nil and SwitchAction_isEnableSupply_method:call(ProgressSwitchActionSupplyManager) == true then
        SwitchAction_supply_method:call(ProgressSwitchActionSupplyManager);
    end

    local ProgressNoteRewardManager = Constants.SDK.get_managed_singleton("snow.progress.ProgressNoteRewardManager");
    if ProgressNoteRewardManager ~= nil and (checkSupplyAnyFigurine_method:call(ProgressNoteRewardManager) == true or checkSupplyAnyFigurine_MR_method:call(ProgressNoteRewardManager) == true) then
        Note_supply_method:call(ProgressNoteRewardManager);
    end
end

function this.init()
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method(".ctor"), PreHook_ctor, PostHook_ctor);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("start"), PreHook_getTalkTarget, PostHook_getTalkTarget);
    Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("onLoad"), PreHook_getTalkTarget, PostHook_getTalkTarget);
    Constants.SDK.hook(Constants.SDK.find_type_definition("snow.VillageMapManager"):get_method("getCurrentMapNo"), nil, PostHook_getCurrentMapNo);
end

return this;