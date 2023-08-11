local require = _G.require;
local Constants = require("Constants.Constants");
local AutoArgosy = require("AutoSupply.AutoArgosy");
local CohootSupply = require("AutoSupply.AutoCohootSupply");
local InventorySupply = require("AutoSupply.AutoInventorySupply");
local AutoTicketsSupply = require("AutoSupply.AutoTicketsSupply");

local find_type_definition = Constants.sdk.find_type_definition;
local to_managed_object = Constants.sdk.to_managed_object;
local get_managed_singleton = Constants.sdk.get_managed_singleton;
local hook = Constants.sdk.hook;
local to_int64 = Constants.sdk.to_int64;

local WwiseChangeSpaceWatcher_type_def = Constants.type_definitions.WwiseChangeSpaceWatcher_type_def;
--
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
	SendMessage(nil, Restock(to_managed_object(args[2]) or get_managed_singleton("snow.data.EquipDataManager"), to_int64(args[3])));
end
hook(Constants.type_definitions.EquipDataManager_type_def:get_method("applyEquipMySet(System.Int32)"), PreHook_applyEquipMySet);
--
local function campStart()
	SendMessage(nil, Restock(get_managed_singleton("snow.data.EquipDataManager"), nil));
end
hook(find_type_definition("snow.gui.fsm.camp.GuiCampFsmManager"):get_method("start"), nil, campStart);
--
local isOnVillageStarted = false;

local function onVillageStart()
	talkHandler();

	if isOnVillageStarted ~= true then
		isOnVillageStarted = true;
		local ChatManager = get_managed_singleton("snow.gui.ChatManager");

		cohootSupply();
		if autoArgosy() == true then
			SendMessage(ChatManager, "교역 아이템을 받았습니다");
		end
		SendMessage(ChatManager, Restock(get_managed_singleton("snow.data.EquipDataManager"), nil));
	end
end
hook(WwiseChangeSpaceWatcher_type_def:get_method("onVillageStart"), nil, onVillageStart);
--
local function onVillageEnd()
	isOnVillageStarted = false;
end
hook(WwiseChangeSpaceWatcher_type_def:get_method("onVillageEnd"), nil, onVillageEnd);
--
InventorySupply.init();
AutoTicketsSupply.init();