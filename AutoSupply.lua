local require = require;
local Constants = require("Constants.Constants");
local AutoArgosy = require("AutoSupply.AutoArgosy");
local CohootSupply = require("AutoSupply.AutoCohootSupply");
local InventorySupply = require("AutoSupply.AutoInventorySupply");
local AutoTicketsSupply = require("AutoSupply.AutoTicketsSupply");

local find_type_definition = Constants.sdk.find_type_definition;
local to_managed_object = Constants.sdk.to_managed_object;
local get_managed_singleton = Constants.sdk.get_managed_singleton;
local hook = Constants.sdk.hook;
--
local type_definitions = Constants.type_definitions;
local to_uint = Constants.to_uint;
local SendMessage = Constants.SendMessage;
--
local Restock = InventorySupply.Restock;
--
local talkHandler = AutoTicketsSupply.talkHandler;
--
local cohootSupply = CohootSupply.Supply;
--
local autoArgosy = AutoArgosy.autoArgosy;
--
local function PreHook_applyEquipMySet(args)
    SendMessage(nil, Restock(to_managed_object(args[2]) or get_managed_singleton("snow.data.EquipDataManager"), to_uint(args[3])));
end
hook(type_definitions.EquipDataManager_type_def:get_method("applyEquipMySet(System.Int32)"), PreHook_applyEquipMySet);
--
local function campStart()
    SendMessage(nil, Restock(get_managed_singleton("snow.data.EquipDataManager"), nil));
end
hook(find_type_definition("snow.gui.fsm.camp.GuiCampFsmManager"):get_method("start"), nil, campStart);
--
local function onVillageStart()
    talkHandler();

    if Constants.isOnVillageStarted ~= true then
        Constants.isOnVillageStarted = true;

        cohootSupply();
        local ChatManager = get_managed_singleton("snow.gui.ChatManager");
        if autoArgosy() == true then
            SendMessage(ChatManager, "교역 아이템을 받았습니다");
        end
        SendMessage(ChatManager, Restock(get_managed_singleton("snow.data.EquipDataManager"), nil));
    end
end
hook(type_definitions.WwiseChangeSpaceWatcher_type_def:get_method("onVillageStart"), nil, onVillageStart);
--
AutoTicketsSupply.init();