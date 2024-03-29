local require = _G.require;
local Constants = require("Constants.Constants");
local AutoArgosy = require("AutoSupply.AutoArgosy");
local CohootSupply = require("AutoSupply.AutoCohootSupply");
local InventorySupply = require("AutoSupply.AutoInventorySupply");
local AutoTicketsSupply = require("AutoSupply.AutoTicketsSupply");
local AutoMysteryPoint = require("AutoSupply.AutoMysteryPoint");

local sdk = Constants.sdk;
local hook = sdk.hook;
local to_int64 = sdk.to_int64;
local find_type_definition = sdk.find_type_definition;

local WwiseChangeSpaceWatcher_type_def = find_type_definition("snow.wwise.WwiseChangeSpaceWatcher");
--
local Restock = InventorySupply.Restock;
--
local talkHandler = AutoTicketsSupply.talkHandler;
--
local cohootSupply = CohootSupply.Supply;
--
local autoArgosy = AutoArgosy.autoArgosy;
--
local autoExchange = AutoMysteryPoint.exchange;
--
local function PreHook_applyEquipMySet(args)
	Constants:SendMessage(Restock(to_int64(args[3])));
end
hook(Constants.type_definitions.EquipDataManager_type_def:get_method("applyEquipMySet(System.Int32)"), PreHook_applyEquipMySet);
--
local function campStart()
	Constants:SendMessage(Restock(nil));
end
hook(find_type_definition("snow.gui.fsm.camp.GuiCampFsmManager"):get_method("start"), nil, campStart);
--
local isOnVillageStarted = false;

local function onVillageStart()
	talkHandler();

	if isOnVillageStarted ~= true then
		isOnVillageStarted = true;
		cohootSupply();
		if autoArgosy() == true then
			Constants:SendMessage("교역 아이템을 받았습니다");
		end
		autoExchange();
		Constants:SendMessage(Restock(nil));
	end
end
hook(WwiseChangeSpaceWatcher_type_def:get_method("onVillageStart"), nil, onVillageStart);
--
local function onVillageEnd()
	isOnVillageStarted = false;
end
hook(WwiseChangeSpaceWatcher_type_def:get_method("onVillageEnd"), nil, onVillageEnd);
--
AutoTicketsSupply.init();