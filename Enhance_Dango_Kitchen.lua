local Constants = _G.require("Constants.Constants");

local find_type_definition = Constants.sdk.find_type_definition;
local to_managed_object = Constants.sdk.to_managed_object;
local get_managed_singleton = Constants.sdk.get_managed_singleton;
local hook = Constants.sdk.hook;

local getMealTicketCount = Constants.getMealTicketCount;
local setMealTicket = Constants.setMealTicket;
local DangoLogStart = Constants.DangoLogStart;

-- Auto Dango Ticket
local MealFunc_type_def = Constants.type_definitions.MealFunc_type_def;
local getMealTicketFlag_method = MealFunc_type_def:get_method("getMealTicketFlag");
local setMealTicketFlag_method = MealFunc_type_def:get_method("setMealTicketFlag(System.Boolean)");

-- Skip Dango Song cache
local GuiKitchen_BBQ_type_def = find_type_definition("snow.gui.GuiKitchen_BBQ");
local getDemoState_method = GuiKitchen_BBQ_type_def:get_method("getDemoState");
local BBQ_DemoHandler_field = GuiKitchen_BBQ_type_def:get_field("_DemoHandler");

local BBQ_DemoState_type_def = getDemoState_method:get_return_type();
local BBQ_DemoState = {
	[BBQ_DemoState_type_def:get_field("Update"):get_data(nil)] = true,
	[BBQ_DemoState_type_def:get_field("ResultDemoUpdate"):get_data(nil)] = true
};

local KitchenFsm_type_def = find_type_definition("snow.gui.fsm.kitchen.GuiKitchenFsmManager");
local get_KitchenCookDemoHandler_method = KitchenFsm_type_def:get_method("get_KitchenCookDemoHandler");
local get_KitchenEatDemoHandler_method = KitchenFsm_type_def:get_method("get_KitchenEatDemoHandler");
local get_KitchenDangoLogParam_method = KitchenFsm_type_def:get_method("get_KitchenDangoLogParam");

local GuiKitchenCookingEventDemoFsmAction_type_def = find_type_definition("snow.gui.fsm.kitchen.GuiKitchenCookingEventDemoFsmAction");
local CookingDemoState_field = GuiKitchenCookingEventDemoFsmAction_type_def:get_field("_DemoState");
local CookingDemoState_Demo_Update = CookingDemoState_field:get_type():get_field("Demo_Update"):get_data(nil);

local GuiKitchenEatingEventDemoFsmAction_type_def = find_type_definition("snow.gui.fsm.kitchen.GuiKitchenEatingEventDemoFsmAction");
local EatingDemoState_field = GuiKitchenEatingEventDemoFsmAction_type_def:get_field("_DemoState");
local EatingDemoState_Demo_Update = EatingDemoState_field:get_type():get_field("Demo_Update"):get_data(nil);

local reqFinish_method = get_KitchenCookDemoHandler_method:get_return_type():get_method("reqFinish(System.Single)");

-- Auto Dango Ticket
local function PreHook_updateList(args)
	local MealFunc = to_managed_object(args[2]);
	if getMealTicketFlag_method:call(MealFunc) == false then
		setMealTicket(MealFunc, getMealTicketCount() > 0);
	end
end
hook(MealFunc_type_def:get_method("updateList(System.Boolean)"), PreHook_updateList);

-- Skip Dango Song Main Function
--CookDemo
local function cookingDemo_Body(obj)
	if CookingDemoState_field:get_data(obj) == CookingDemoState_Demo_Update then
		reqFinish_method:call(get_KitchenCookDemoHandler_method:call(get_managed_singleton("snow.gui.fsm.kitchen.GuiKitchenFsmManager")), 0.0);
	end
end

local GuiKitchenCookingEventDemoFsmAction = nil;
local function PreHook_CookingDemoUpdate(args)
	GuiKitchenCookingEventDemoFsmAction = to_managed_object(args[2]);
	cookingDemo_Body(GuiKitchenCookingEventDemoFsmAction);
end
local function PostHook_CookingDemoUpdate()
	cookingDemo_Body(GuiKitchenCookingEventDemoFsmAction);
	GuiKitchenCookingEventDemoFsmAction = nil;
end
hook(GuiKitchenCookingEventDemoFsmAction_type_def:get_method("update(via.behaviortree.ActionArg)"), PreHook_CookingDemoUpdate, PostHook_CookingDemoUpdate);

--EatDemo
local showDangoLog = false;

local function eatingDemo_Body(obj)
	if EatingDemoState_field:get_data(obj) == EatingDemoState_Demo_Update then
		reqFinish_method:call(get_KitchenEatDemoHandler_method:call(get_managed_singleton("snow.gui.fsm.kitchen.GuiKitchenFsmManager")), 0.0);
		showDangoLog = true;
	end
end

local GuiKitchenEatingEventDemoFsmAction = nil;
local function PreHook_EatingDemoUpdate(args)
	GuiKitchenEatingEventDemoFsmAction = to_managed_object(args[2]);
	eatingDemo_Body(GuiKitchenEatingEventDemoFsmAction);
end
local function PostHook_EatingDemoUpdate()
	eatingDemo_Body(GuiKitchenEatingEventDemoFsmAction);
	GuiKitchenEatingEventDemoFsmAction = nil;
end
hook(GuiKitchenEatingEventDemoFsmAction_type_def:get_method("update(via.behaviortree.ActionArg)"), PreHook_EatingDemoUpdate, PostHook_EatingDemoUpdate);

local function PostHook_requestAutoSaveAll()
	if showDangoLog == true then
		showDangoLog = false;
		DangoLogStart(get_KitchenDangoLogParam_method:call(get_managed_singleton("snow.gui.fsm.kitchen.GuiKitchenFsmManager")));
	end
end
hook(find_type_definition("snow.SnowSaveService"):get_method("requestAutoSaveAll"), nil, PostHook_requestAutoSaveAll);

--BBQ
local function bbqDemo_Body(obj)
	if BBQ_DemoState[getDemoState_method:call(obj)] == true then
		reqFinish_method:call(BBQ_DemoHandler_field:get_data(obj), 0.0);
	end
end

local GuiKitchen_BBQ = nil;
local function PreHook_BBQ_updatePlayDemo(args)
	GuiKitchen_BBQ = to_managed_object(args[2]);
	bbqDemo_Body(GuiKitchen_BBQ);
end
local function PostHook_BBQ_updatePlayDemo()
	bbqDemo_Body(GuiKitchen_BBQ);
	GuiKitchen_BBQ = nil;
end
hook(GuiKitchen_BBQ_type_def:get_method("updatePlayDemo"), PreHook_BBQ_updatePlayDemo, PostHook_BBQ_updatePlayDemo);