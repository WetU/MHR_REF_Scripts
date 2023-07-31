local Constants = require("Constants.Constants");
local AutoArgosy = require("AutoSupply.AutoArgosy");
local CohootSupply = require("AutoSupply.AutoCohootSupply");
local InventorySupply = require("AutoSupply.AutoInventorySupply");
local AutoTicketsSupply = require("AutoSupply.AutoTicketsSupply");
--
local function PreHook_applyEquipMySet(args)
    Constants.SendMessage(InventorySupply.Restock(sdk.to_managed_object(args[2]) or sdk.get_managed_singleton("snow.data.EquipDataManager"), Constants.to_uint(args[3])));
end
sdk.hook(Constants.type_definitions.EquipDataManager_type_def:get_method("applyEquipMySet(System.Int32)"), PreHook_applyEquipMySet);
--
local function campStart()
    Constants.SendMessage(InventorySupply.Restock(sdk.get_managed_singleton("snow.data.EquipDataManager"), nil));
end
sdk.hook(sdk.find_type_definition("snow.gui.fsm.camp.GuiCampFsmManager"):get_method("start"), nil, campStart);
--
local function onVillageStart()
    AutoTicketsSupply.talkHandler();

    if Constants.isOnVillageStarted ~= true then
        Constants.isOnVillageStarted = true;
        CohootSupply.Supply();
        if AutoArgosy.autoArgosy() == true then
            Constants.SendMessage("교역 아이템을 받았습니다");
        end
        Constants.SendMessage(InventorySupply.Restock(sdk.get_managed_singleton("snow.data.EquipDataManager"), nil));
    end
end
sdk.hook(Constants.type_definitions.WwiseChangeSpaceWatcher_type_def:get_method("onVillageStart"), nil, onVillageStart);
--
AutoTicketsSupply.init();