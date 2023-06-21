local Constants = require("Constants.Constants");
if not Constants then
	return;
end
--
local settings = Constants.JSON.load_file("no_bullshit.json") or {enable = true};
if settings.enable == nil then
    settings.enable = true;
end
--
local NpcTalkMessageCtrl_type_def = Constants.SDK.find_type_definition("snow.npc.NpcTalkMessageCtrl");
local get_NpcId_method = NpcTalkMessageCtrl_type_def:get_method("get_NpcId"); -- retval
local resetTalkDispName_method = NpcTalkMessageCtrl_type_def:get_method("resetTalkDispName");
local executeTalkAction_method = NpcTalkMessageCtrl_type_def:get_method("executeTalkAction");
local set_DetermineSpeechBalloonMessage_method = NpcTalkMessageCtrl_type_def:get_method("set_DetermineSpeechBalloonMessage(System.String)");
local set_SpeechBalloonAttr_method = NpcTalkMessageCtrl_type_def:get_method("set_SpeechBalloonAttr(snow.npc.TalkAttribute)");

local get_CurrentVillageNo_method = Constants.SDK.find_type_definition("snow.VillageAreaManager"):get_method("get_CurrentVillageNo");

local VillageNo_type_def = get_CurrentVillageNo_method:get_return_type();
local KAMURA = VillageNo_type_def:get_field("Village01"):get_data(nil);
local ELGADO = VillageNo_type_def:get_field("Village02"):get_data(nil);

local TalkAttribute_NONE = Constants.SDK.find_type_definition("snow.npc.TalkAttribute"):get_field("TALK_ATTR_NONE"):get_data(nil);

local NpcId_type_def = get_NpcId_method:get_return_type();
local npcList = {
    ["KAMURA"] = {
        NpcId_type_def:get_field("nid004"):get_data(nil),  -- Yomogi
    },
    ["ELGADO"] = {
        NpcId_type_def:get_field("nid503"):get_data(nil),  -- Bahari
        NpcId_type_def:get_field("nid608"):get_data(nil),  -- Azuki
        NpcId_type_def:get_field("nid715"):get_data(nil)   -- Pingarh
    }
};
--
local ctorActivated = false;
local npcTalkMessageList = nil;

local function hasNpcId(npcid)
    if npcid ~= nil then
        for village, ids in Constants.LUA.pairs(npcList) do
            for _, id in Constants.LUA.pairs(ids) do
                if id == npcid then
                    return village;
                end
            end
        end
    end
    return nil;
end

local function talkAction(npcTalkMessageCtrl)
    if ctorActivated then
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
    if settings.enable then
        ctorObj = Constants.SDK.to_managed_object(args[2]);
    end
end
local function PostHook_ctor()
    if ctorObj then
        ctorActivated = true;
        if not npcTalkMessageList then
            npcTalkMessageList = {ctorObj};
        else
            Constants.LUA.table_insert(npcTalkMessageList, ctorObj);
        end
    end
    ctorObj = nil;
end

local NpcTalkMessageCtrl = nil;
local function PreHook_getTalkTarget(args)
    if settings.enable and not ctorActivated then
        NpcTalkMessageCtrl = Constants.SDK.to_managed_object(args[2]);
    end
end

local function PostHook_getTalkTarget()
    if NpcTalkMessageCtrl then
        local npcId = get_NpcId_method:call(NpcTalkMessageCtrl);
        if npcId ~= nil and hasNpcId(npcId) then
            if not npcTalkMessageList then
                npcTalkMessageList = {npcId = NpcTalkMessageCtrl};
            else
                if not npcTalkMessageList[npcId] then
                    npcTalkMessageList[npcId] = NpcTalkMessageCtrl;
                end
            end
        end
    end
    NpcTalkMessageCtrl = nil;
end

local function PostHook_getCurrentMapNo(retval)
    if settings.enable and npcTalkMessageList then
        local VillageAreaManager = Constants.SDK.get_managed_singleton("snow.VillageAreaManager");
        if VillageAreaManager then
            local currentVillageNo = get_CurrentVillageNo_method:call(VillageAreaManager);
            if currentVillageNo ~= nil then
                local isKamura = currentVillageNo == KAMURA;
                local isElgado = currentVillageNo == ELGADO;
                if isKamura or isElgado then
                    for k, v in Constants.LUA.pairs(npcTalkMessageList) do
                        if v ~= nil and Constants.SDK.is_managed_object(v) then
                            local npcVillage = ctorActivated and hasNpcId(v:call("get_NpcId")) or hasNpcId(k);
                            if npcVillage ~= nil then
                                if (npcVillage == "KAMURA" and isKamura) or (npcVillage == "ELGADO" and isElgado) then
                                    talkAction(v);
                                    npcTalkMessageList[k] = nil;
                                end
                            else
                                npcTalkMessageList[k] = nil;
                            end
                        else
                            npcTalkMessageList[k] = nil;
                        end
                    end
                    ctorActivated = false;
                end
            end
        end
    end
    return retval;
end

Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method(".ctor"), PreHook_ctor, PostHook_ctor);
Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("start"), PreHook_getTalkTarget, PostHook_getTalkTarget);
Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("onLoad"), PreHook_getTalkTarget, PostHook_getTalkTarget);
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.VillageMapManager"):get_method("getCurrentMapNo"), nil, PostHook_getCurrentMapNo);
--
local function SaveSettings()
    Constants.JSON.dump_file("no_bullshit.json", settings);
end

Constants.RE.on_config_save(SaveSettings);
Constants.RE.on_draw_ui(function()
	if Constants.IMGUI.tree_node("No Bullshit") then
        local changed = false;
		changed, settings.enable = Constants.IMGUI.checkbox("Enabled", settings.enable);
        if changed then
            if not settings.enable then
                npcTalkMessageList = nil;
            end
            SaveSettings();
        end
		Constants.IMGUI.tree_pop();
	end
end);

Constants.RE.on_frame(function()
    if npcTalkMessageList then
        local valid = false;
        for _, v in Constants.LUA.pairs(npcTalkMessageList) do
            if v ~= nil then
                valid = true;
                break;
            end
        end
        if valid == false then
            npcTalkMessageList = nil;
            ctorActivated = false;
        end
    end
end);