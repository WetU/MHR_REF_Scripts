local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_to_managed_object = sdk.to_managed_object;
local sdk_to_int64 = sdk.to_int64;
local sdk_hook = sdk.hook;
local sdk_CALL_ORIGINAL = sdk.PreHookResult.CALL_ORIGINAL;

local json = json;
local json_dump_file = json.dump_file;
local json_load_file = json.load_file;

local imgui = imgui;
local imgui_tree_node = imgui.tree_node;
local imgui_checkbox = imgui.checkbox;
local imgui_tree_pop = imgui.tree_pop;

local re = re;
local re_on_draw_ui = re.on_draw_ui;
local re_on_config_save = re.on_config_save;

local table = table;
local table_insert = table.insert;

local pairs = pairs;
--
local settings = {};

local loadedSettings = json_load_file("no_bullshit.json");
settings = loadedSettings or {enable = true};

if settings.enable == nil then
    settings.enable = true;
end
--
local NpcTalkMessageCtrl_type_def = sdk_find_type_definition("snow.npc.NpcTalkMessageCtrl");
local constructor_method = NpcTalkMessageCtrl_type_def:get_method(".ctor");
local start_method = NpcTalkMessageCtrl_type_def:get_method("start");
local onLoad_method = NpcTalkMessageCtrl_type_def:get_method("onLoad");
local get_NpcId_method = NpcTalkMessageCtrl_type_def:get_method("get_NpcId");
local resetTalkDispName_method = NpcTalkMessageCtrl_type_def:get_method("resetTalkDispName");
local executeTalkAction_method = NpcTalkMessageCtrl_type_def:get_method("executeTalkAction");
local set_DetermineSpeechBalloonMessage_method = NpcTalkMessageCtrl_type_def:get_method("set_DetermineSpeechBalloonMessage(System.String)");
local set_SpeechBalloonAttr_method = NpcTalkMessageCtrl_type_def:get_method("set_SpeechBalloonAttr(snow.npc.TalkAttribute)");

local getCurrentMapNo_method = sdk_find_type_definition("snow.VillageMapManager"):get_method("getCurrentMapNo");

local VillageMapNoType_type_def = getCurrentMapNo_method:get_return_type();
local KAMURA = VillageMapNoType_type_def:get_field("No00"):get_data(nil);
local ELGADO = VillageMapNoType_type_def:get_field("No01"):get_data(nil);

local TalkAttribute_NONE = sdk_find_type_definition("snow.npc.TalkAttribute"):get_field("TALK_ATTR_NONE"):get_data(nil);

local NpcId_type_def = get_NpcId_method:get_return_type();
local npcList = {
    ["KAMURA"] = {
        [NpcId_type_def:get_field("nid001"):get_data(nil)] = true,  -- Fugen
        [NpcId_type_def:get_field("nid003"):get_data(nil)] = true,  -- Kagero
        [NpcId_type_def:get_field("nid004"):get_data(nil)] = true,  -- Yomogi
        [NpcId_type_def:get_field("nid101"):get_data(nil)] = true,  -- Hojo
        [NpcId_type_def:get_field("nid306"):get_data(nil)] = true   -- Iori
    },
    ["ELGADO"] = {
        [NpcId_type_def:get_field("nid502"):get_data(nil)] = true,  -- Galleus
        [NpcId_type_def:get_field("nid503"):get_data(nil)] = true,  -- Bahari
        [NpcId_type_def:get_field("nid606"):get_data(nil)] = true,  -- Nagi
        [NpcId_type_def:get_field("nid607"):get_data(nil)] = true,  -- Oboro
        [NpcId_type_def:get_field("nid608"):get_data(nil)] = true,  -- Azuki
        [NpcId_type_def:get_field("nid715"):get_data(nil)] = true   -- Pingarh
    }
};
--
local npcTalkMessageList = nil;

local NpcTalkMessageCtrl_ctor = nil;
sdk_hook(constructor_method, function(args)
    if settings.enable then
        NpcTalkMessageCtrl_ctor = sdk_to_managed_object(args[2]);
    end
    return sdk_CALL_ORIGINAL;
end, function()
    if NpcTalkMessageCtrl_ctor then
        if not npcTalkMessageList then
            npcTalkMessageList = {};
        end
        table_insert(npcTalkMessageList, NpcTalkMessageCtrl_ctor);
    end
    NpcTalkMessageCtrl_ctor = nil;
end);

local NpcTalkMessageCtrl = nil;
local function pre_getTalkTarget(args)
    if settings.enable then
        NpcTalkMessageCtrl = sdk_to_managed_object(args[2]);
    end
    return sdk_CALL_ORIGINAL;
end

local function post_getTalkTarget()
    if NpcTalkMessageCtrl then
        if not npcTalkMessageList then
            npcTalkMessageList = {};
        end

        local npcId = get_NpcId_method:call(NpcTalkMessageCtrl);
        if npcId ~= nil then
            if npcList[npcId] and not npcTalkMessageList[npcId] then
                npcTalkMessageList[npcId] = NpcTalkMessageCtrl;
            end
        else
            table_insert(npcTalkMessageList, NpcTalkMessageCtrl);
        end
    end
    NpcTalkMessageCtrl = nil;
end

sdk_hook(start_method, pre_getTalkTarget, post_getTalkTarget);
sdk_hook(onLoad_method, pre_getTalkTarget, post_getTalkTarget);

local function talkAction(npcTalkMessageCtrl)
    resetTalkDispName_method:call(npcTalkMessageCtrl);
    executeTalkAction_method:call(npcTalkMessageCtrl);
    set_DetermineSpeechBalloonMessage_method:call(npcTalkMessageCtrl, nil);
    set_SpeechBalloonAttr_method:call(npcTalkMessageCtrl, TALK_ATTR_NONE);
end

sdk_hook(getCurrentMapNo_method, nil, function(retval)
    if settings.enable and npcTalkMessageList ~= nil then
        local currentVillageMapNo = sdk_to_int64(retval) & 0xFFFFFFFF;
        if currentVillageMapNo ~= nil then
            local isKamura = currentVillageMapNo == KAMURA;
            for k, v in pairs(npcTalkMessageList) do
                if v:get_reference_count() > 0 then
                    if npcList.KAMURA[k] and isKamura then
                        talkAction(v);
                    elseif npcList.ELGADO[k] and not isKamura then
                        talkAction(v);
                    else
                        local NpcId = get_NpcId_method:call(v);
                        if NpcId ~= nil then
                            if npcList.KAMURA[NpcId] and isKamura then
                                talkAction(v);
                            elseif npcList.ELGADO[NpcId] and not isKamura then
                                talkAction(v);
                            end
                        end
                    end
                end
            end
        end
        npcTalkMessageList = nil;
    end
    return retval;
end);
--
local function SaveSettings()
    json_dump_file("no_bullshit.json", settings);
end

re_on_config_save(SaveSettings);

re_on_draw_ui(function()
	if imgui_tree_node("No Bullshit") then
        local changed = false;
		changed, settings.enable = imgui_checkbox("Enabled", settings.enable);
        if changed then
            if not settings.enable then
                npcTalkMessageList = nil;
            end
            SaveSettings();
        end
		imgui_tree_pop();
	end
end);