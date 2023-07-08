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
local isVillageStarted = false;

local function SendMessage(text)
    local ChatManager = Constants.SDK.get_managed_singleton("snow.gui.ChatManager");
    if ChatManager ~= nil then
        reqAddChatInfomation_method:call(ChatManager, text, 2289944406);
    end
end
--
local EquipDataManager = nil;
local setIdx = nil;
local function PreHook_applyEquipMySet(args)
    EquipDataManager = Constants.SDK.to_managed_object(args[2]);
    setIdx = Constants.SDK.to_int64(args[3]) & 0xFFFFFFFF;
end
local function PostHook_applyEquipMySet(retval)
    SendMessage(InventorySupply.Restock(EquipDataManager, setIdx));
    EquipDataManager = nil;
    setIdx = nil;
    return retval;
end
Constants.SDK.hook(Constants.type_definitions.EquipDataManager_type_def:get_method("applyEquipMySet(System.Int32)"), PreHook_applyEquipMySet, PostHook_applyEquipMySet);
--
local function campStart()
    SendMessage(InventorySupply.Restock(nil, nil));
end
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.camp.GuiCampFsmManager"):get_method("start"), nil, campStart);
--
local function onChangedGameStatus(args)
    if Constants.SDK.to_int64(args[3]) ~= Constants.GameStatusType.Village then
        isVillageStarted = false;
        return;
    end

    if AutoArgosy.autoArgosy() == true then
        SendMessage("교역선 아이템을 받았습니다");
    end
    SendMessage(InventorySupply.Restock(nil, nil));
end
Constants.SDK.hook(Constants.type_definitions.DataManager_type_def:get_method("onChangedGameStatus(snow.SnowGameManager.StatusType)"), onChangedGameStatus);
--
local function onVillageStart()
    if isVillageStarted == false then
        isVillageStarted = true;
        CohootSupply.Supply();
    end
end
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.wwise.WwiseChangeSpaceWatcher"):get_method("onVillageStart"), nil, onVillageStart);
--
AutoTicketsSupply.init();