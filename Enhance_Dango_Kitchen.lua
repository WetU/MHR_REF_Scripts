local Constants = require("Constants.Constants");
-- Auto Dango Ticket
local MealFunc_type_def = sdk.find_type_definition("snow.facility.kitchen.MealFunc");
local setMealTicketFlag_method = MealFunc_type_def:get_method("setMealTicketFlag(System.Boolean)");
-- Skip Dango Song cache
local GuiKitchen_BBQ_type_def = sdk.find_type_definition("snow.gui.GuiKitchen_BBQ");
local getDemoState_method = GuiKitchen_BBQ_type_def:get_method("getDemoState");
local BBQ_DemoHandler_field = GuiKitchen_BBQ_type_def:get_field("_DemoHandler");

local BBQ_DemoState_type_def = getDemoState_method:get_return_type();
local BBQ_DemoState = {
	["Update"] = BBQ_DemoState_type_def:get_field("Update"):get_data(nil),
	["ResultDemoUpdate"] = BBQ_DemoState_type_def:get_field("ResultDemoUpdate"):get_data(nil)
};

local reqDangoLogStart_method = Constants.type_definitions.GuiManager_type_def:get_method("reqDangoLogStart(snow.gui.GuiDangoLog.DangoLogParam, System.Single)");

local KitchenFsm_type_def = sdk.find_type_definition("snow.gui.fsm.kitchen.GuiKitchenFsmManager");
local get_KitchenCookDemoHandler_method = KitchenFsm_type_def:get_method("get_KitchenCookDemoHandler");
local get_KitchenEatDemoHandler_method = KitchenFsm_type_def:get_method("get_KitchenEatDemoHandler");
local get_KitchenDangoLogParam_method = KitchenFsm_type_def:get_method("get_KitchenDangoLogParam");

local GuiKitchenCookingEventDemoFsmAction_type_def = sdk.find_type_definition("snow.gui.fsm.kitchen.GuiKitchenCookingEventDemoFsmAction");
local CookingDemoState_field = GuiKitchenCookingEventDemoFsmAction_type_def:get_field("_DemoState");
local CookingDemoState_Demo_Update = CookingDemoState_field:get_type():get_field("Demo_Update"):get_data(nil);

local GuiKitchenEatingEventDemoFsmAction_type_def = sdk.find_type_definition("snow.gui.fsm.kitchen.GuiKitchenEatingEventDemoFsmAction");
local EatingDemoState_field = GuiKitchenEatingEventDemoFsmAction_type_def:get_field("_DemoState");
local EatingDemoState_Demo_Update = EatingDemoState_field:get_type():get_field("Demo_Update"):get_data(nil);

local reqFinish_method = get_KitchenCookDemoHandler_method:get_return_type():get_method("reqFinish(System.Single)");
-- Auto Dango Ticket
local function PreHook_updateList(args)
	setMealTicketFlag_method:call(sdk.to_managed_object(args[2]), true);
end
sdk.hook(MealFunc_type_def:get_method("updateList(System.Boolean)"), PreHook_updateList);
-- Skip Dango Song Main Function
--CookDemo
local function PreHook_CookingDemoUpdate(args)
	if CookingDemoState_field:get_data(sdk.to_managed_object(args[2])) == CookingDemoState_Demo_Update then
		reqFinish_method:call(get_KitchenCookDemoHandler_method:call(sdk.get_managed_singleton("snow.gui.fsm.kitchen.GuiKitchenFsmManager")), 0.0);
	end
end
sdk.hook(GuiKitchenCookingEventDemoFsmAction_type_def:get_method("update(via.behaviortree.ActionArg)"), PreHook_CookingDemoUpdate);
--EatDemo
local showDangoLog = false;

local function PreHook_EatingDemoUpdate(args)
	if EatingDemoState_field:get_data(sdk.to_managed_object(args[2])) == EatingDemoState_Demo_Update then
		reqFinish_method:call(get_KitchenEatDemoHandler_method:call(sdk.get_managed_singleton("snow.gui.fsm.kitchen.GuiKitchenFsmManager")), 0.0);
		showDangoLog = true;
	end
end
sdk.hook(GuiKitchenEatingEventDemoFsmAction_type_def:get_method("update(via.behaviortree.ActionArg)"), PreHook_EatingDemoUpdate);

local function PostHook_requestAutoSaveAll()
	if showDangoLog == true then
		showDangoLog = false;
		reqDangoLogStart_method:call(sdk.get_managed_singleton("snow.gui.GuiManager"), get_KitchenDangoLogParam_method:call(sdk.get_managed_singleton("snow.gui.fsm.kitchen.GuiKitchenFsmManager")), 5.0);
	end
end
sdk.hook(sdk.find_type_definition("snow.SnowSaveService"):get_method("requestAutoSaveAll"), nil, PostHook_requestAutoSaveAll);
--BBQ
local function PreHook_BBQ_updatePlayDemo(args)
	local GuiKitchen_BBQ = sdk.to_managed_object(args[2]);
	local DemoState = getDemoState_method:call(GuiKitchen_BBQ);

	for _, v in pairs(BBQ_DemoState) do
		if DemoState == v then
			reqFinish_method:call(BBQ_DemoHandler_field:get_data(GuiKitchen_BBQ), 0.0);
			break;
		end
	end
end
sdk.hook(GuiKitchen_BBQ_type_def:get_method("updatePlayDemo"), PreHook_BBQ_updatePlayDemo);