local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_to_managed_object = sdk.to_managed_object;
local sdk_hook = sdk.hook;
local sdk_CALL_ORIGINAL = sdk.PreHookResult.CALL_ORIGINAL;

local json = json;
local jsonAvailable = json ~= nil;
local json_dump_file = jsonAvailable and json.dump_file or nil;
local json_load_file = jsonAvailable and json.load_file or nil;

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

local TalkAttribute_NONE = sdk_find_type_definition("snow.npc.TalkAttribute"):get_field("TALK_ATTR_NONE"):get_data(nil);

local NpcId_type_def = get_NpcId_method:get_return_type();
local npcList = {
    -- Kamura
    [NpcId_type_def:get_field("nid001"):get_data(nil)] = true,  -- Fugen
    [NpcId_type_def:get_field("nid003"):get_data(nil)] = true,  -- Kagero
    [NpcId_type_def:get_field("nid004"):get_data(nil)] = true,  -- Yomogi
    [NpcId_type_def:get_field("nid101"):get_data(nil)] = true, -- Hojo
    [NpcId_type_def:get_field("nid306"):get_data(nil)] = true, -- Iori
    -- Elgado
    [NpcId_type_def:get_field("nid502"):get_data(nil)] = true, -- Galleus
    [NpcId_type_def:get_field("nid503"):get_data(nil)] = true, -- Bahari
    [NpcId_type_def:get_field("nid606"):get_data(nil)] = true, -- Nagi
    [NpcId_type_def:get_field("nid607"):get_data(nil)] = true, -- Oboro
    [NpcId_type_def:get_field("nid608"):get_data(nil)] = true, -- Azuki
    [NpcId_type_def:get_field("nid715"):get_data(nil)] = true -- Pingarh
};
--
local settings = {
    enable = true
};

local ctorActivated = false;
local npcTalkMessageList = {};

local function getTalkTargetCtor(args)
    ctorActivated = true;
    if settings.enable then
        local obj = sdk_to_managed_object(args[2]);
        if obj then
            table_insert(npcTalkMessageList, obj);
        end
    end
end

local function getTalkTarget(args)
    if settings.enable and not ctorActivated then
        local obj = sdk_to_managed_object(args[2]);
        if obj then
            local npcId = get_NpcId_method:call(obj);
            if npcList[npcId] and not npcTalkMessageList[npcId] then
                npcTalkMessageList[npcId] = obj;
            end
        end
    end
    return sdk_CALL_ORIGINAL;
end

local function talkAction(npcTalkMessageCtrl)
    resetTalkDispName_method:call(npcTalkMessageCtrl);
    executeTalkAction_method:call(npcTalkMessageCtrl);
    set_DetermineSpeechBalloonMessage_method:call(npcTalkMessageCtrl, nil);
    set_SpeechBalloonAttr_method:call(npcTalkMessageCtrl, TALK_ATTR_NONE);
end

local function talkHandler(retval)
    if settings.enable then
        if #npcTalkMessageList > 0 then
            if ctorActivated then
                for _, v in pairs(npcTalkMessageList) do
                    local npcId = get_NpcId_method:call(v);
                    if npcList[npcId] then
                        talkAction(v);
                    end
                end
                ctorActivated = false;
            else
                for _, v in pairs(npcTalkMessageList) do
                    talkAction(v);
                end
            end
            npcTalkMessageList = {};
        end
    end
    return retval;
end

local function SaveSettings()
    if json_dump_file then
	    json_dump_file("no_bullshit.json", settings);
    end
end

local function LoadSettings()
    if json_load_file then
	    local loadedSettings = json_load_file("no_bullshit.json");
        if loadedSettings then
            settings = loadedSettings;
        end
    end
end

re_on_draw_ui(function()
	local changed = false;
	if imgui_tree_node("No Bullshit") then
		changed, settings.enable = imgui_checkbox("Enabled", settings.enable);
		imgui_tree_pop();
	end
    if changed then
        SaveSettings();
    end
end);

re_on_config_save(SaveSettings);

LoadSettings();

sdk_hook(constructor_method, getTalkTargetCtor);
sdk_hook(start_method, getTalkTarget);
sdk_hook(onLoad_method, getTalkTarget);
sdk_hook(getCurrentMapNo_method, nil, talkHandler);