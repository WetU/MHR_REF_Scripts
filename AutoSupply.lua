local require = require;
local Constants = require("Constants.Constants");
local AutoArgosy = require("AutoSupply.AutoArgosy");
local CohootSupply = require("AutoSupply.AutoCohootSupply");
local InventorySupply = require("AutoSupply.AutoInventorySupply");
local AutoTicketsSupply = require("AutoSupply.AutoTicketsSupply");

if not Constants
or not AutoArgosy
or not CohootSupply
or not InventorySupply
or not AutoTicketsSupply then
    return;
end
--
local reqAddChatInfomation_method = Constants.SDK.find_type_definition("snow.gui.ChatManager"):get_method("reqAddChatInfomation(System.String, System.UInt32)");
--
local function SendMessage(text)
    if Constants.LUA.type(text) ~= "string" then
        return;
    end

    local ChatManager = Constants.SDK.get_managed_singleton("snow.gui.ChatManager");
    if ChatManager == nil then
        return;
    end

    reqAddChatInfomation_method:call(ChatManager, text, 2289944406);
end
--
local function PreHook_applyEquipMySet(args)
    SendMessage(InventorySupply.Restock(Constants.SDK.to_managed_object(args[2]), Constants.to_uint(args[3])));
end
Constants.SDK.hook(Constants.type_definitions.EquipDataManager_type_def:get_method("applyEquipMySet(System.Int32)"), PreHook_applyEquipMySet);
--
local function campStart()
    SendMessage(InventorySupply.Restock(nil, nil));
end
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.camp.GuiCampFsmManager"):get_method("start"), nil, campStart);
--
local function onVillageStart()
    if Constants.isOnVillageStarted == true then
        return;
    end

    Constants.isOnVillageStarted = true;
    CohootSupply.Supply();
    if AutoArgosy.autoArgosy() == true then
        SendMessage("교역선 아이템을 받았습니다");
    end
    SendMessage(InventorySupply.Restock(nil, nil));
end
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.wwise.WwiseChangeSpaceWatcher"):get_method("onVillageStart"), nil, onVillageStart);
--
AutoTicketsSupply.init();