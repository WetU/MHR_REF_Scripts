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

local VillageMapNoType_type_def = Constants.SDK.find_type_definition("snow.VillageMapManager.MapNoType");
local KAMURA = VillageMapNoType_type_def:get_field("No00"):get_data(nil);
local ELGADO = VillageMapNoType_type_def:get_field("No01"):get_data(nil);

local TalkAttribute_NONE = Constants.SDK.find_type_definition("snow.npc.TalkAttribute"):get_field("TALK_ATTR_NONE"):get_data(nil);

local NpcId_type_def = get_NpcId_method:get_return_type();
local npcList = {
    ["KAMURA"] = {
        NpcId_type_def:get_field("nid001"):get_data(nil),  -- Fugen
        NpcId_type_def:get_field("nid003"):get_data(nil),  -- Kagero
        NpcId_type_def:get_field("nid004"):get_data(nil),  -- Yomogi
        NpcId_type_def:get_field("nid101"):get_data(nil),  -- Hojo
        NpcId_type_def:get_field("nid306"):get_data(nil)   -- Iori
    },
    ["ELGADO"] = {
        NpcId_type_def:get_field("nid502"):get_data(nil),  -- Galleus
        NpcId_type_def:get_field("nid503"):get_data(nil),  -- Bahari
        NpcId_type_def:get_field("nid606"):get_data(nil),  -- Nagi
        NpcId_type_def:get_field("nid607"):get_data(nil),  -- Oboro
        NpcId_type_def:get_field("nid608"):get_data(nil),  -- Azuki
        NpcId_type_def:get_field("nid715"):get_data(nil)   -- Pingarh
    }
};
--
local ctorActivated = false;
local npcTalkMessageList = nil;

local function hasNpcId(npcid)
    for village, ids in Constants.LUA.pairs(npcList) do
        for _, id in Constants.LUA.pairs(ids) do
            if id == npcid then
                return village;
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

local NpcTalkMessageCtrl = nil;
local function pre_getTalkTarget(args)
    if settings.enable and not ctorActivated then
        NpcTalkMessageCtrl = Constants.SDK.to_managed_object(args[2]);
    end
end

local function post_getTalkTarget()
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

local ctorObj = nil;
Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method(".ctor"), function(args)
    if settings.enable then
        ctorObj = Constants.SDK.to_managed_object(args[2]);
    end
end, function()
    if ctorObj then
        ctorActivated = true;
        if not npcTalkMessageList then
            npcTalkMessageList = {};
        end
        Constants.LUA.table_insert(npcTalkMessageList, ctorObj);
    end
    ctorObj = nil;
end);
Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("start"), pre_getTalkTarget, post_getTalkTarget);
Constants.SDK.hook(NpcTalkMessageCtrl_type_def:get_method("onLoad"), pre_getTalkTarget, post_getTalkTarget);
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.VillageMapManager"):get_method("getCurrentMapNo"), nil, function(retval)
    if settings.enable and npcTalkMessageList then
        local currentVillageMapNo = Constants.SDK.to_int64(retval) & 0xFFFFFFFF;
        if currentVillageMapNo ~= nil then
            local isKamura = currentVillageMapNo == KAMURA;
            local isElgado = currentVillageMapNo == ELGADO;
            for k, v in Constants.LUA.pairs(npcTalkMessageList) do
                if v ~= nil and Constants.SDK.is_managed_object(v) then
                    local npcId = ctorActivated and v:call("get_NpcId") or nil;
                    local npcVillage = nil;
                    if npcId ~= nil then
                        npcVillage = hasNpcId(npcId);
                        if npcVillage then
                            if (npcVillage == "KAMURA" and isKamura) or (npcVillage == "ELGADO" and isElgado) then
                                talkAction(v);
                                npcTalkMessageList[k] = nil;
                            end
                        else
                            npcTalkMessageList[k] = nil;
                        end
                    else
                        npcVillage = hasNpcId(k);
                        if npcVillage then
                            if (npcVillage == "KAMURA" and isKamura) or (npcVillage == "ELGADO" and isElgado) then
                                talkAction(v);
                                npcTalkMessageList[k] = nil;
                            end
                        else
                            npcTalkMessageList[k] = nil;
                        end
                    end
                else
                    npcTalkMessageList[k] = nil;
                end
            end
            ctorActivated = false;
        end
    end
    return retval;
end);
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
        for k, v in Constants.LUA.pairs(npcTalkMessageList) do
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