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
    local ChatManager = Constants.SDK.get_managed_singleton("snow.gui.ChatManager");
    if ChatManager then
        reqAddChatInfomation_method:call(ChatManager, text, 2289944406);
    end
end

local EquipDataManager = nil;
local setIdx = nil;
Constants.SDK.hook(Constants.type_definitions.EquipDataManager_type_def:get_method("applyEquipMySet(System.Int32)"), function(args)
    EquipDataManager = Constants.SDK.to_managed_object(args[2]);
    setIdx = Constants.SDK.to_int64(args[3]) & 0xFFFFFFFF;
end, function(retval)
    if EquipDataManager and setIdx ~= nil then
        SendMessage(InventorySupply.Restock(EquipDataManager, setIdx));
    end
    EquipDataManager = nil;
    setIdx = nil;
    return retval;
end);

Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.camp.GuiCampFsmManager"):get_method("start"), nil, function()
    SendMessage(InventorySupply.Restock(nil, nil));
end);

Constants.SDK.hook(Constants.SDK.find_type_definition("snow.wwise.WwiseChangeSpaceWatcher"):get_method("onVillageStart"), nil, function()
    if AutoArgosy.autoArgosy() then
        SendMessage("교역선 아이템을 받았습니다");
    end
    SendMessage(InventorySupply.Restock(nil, nil));
    CohootSupply.Supply();
end);

AutoTicketsSupply.init();