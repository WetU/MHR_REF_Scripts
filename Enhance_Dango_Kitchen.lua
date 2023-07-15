local Constants = require("Constants.Constants");
if not Constants then
	return;
end
-- Auto Dango Ticket
local mealFunc_type_def = Constants.SDK.find_type_definition("snow.facility.kitchen.MealFunc");
local setMealTicketFlag_method = mealFunc_type_def:get_method("setMealTicketFlag(System.Boolean)");
-- Skip Dango Song cache
local GuiKitchen_BBQ_type_def = Constants.SDK.find_type_definition("snow.gui.GuiKitchen_BBQ");
local getDemoState_method = GuiKitchen_BBQ_type_def:get_method("getDemoState");
local BBQ_DemoHandler_field = GuiKitchen_BBQ_type_def:get_field("_DemoHandler");

local BBQ_DemoState_type_def = getDemoState_method:get_return_type();
local BBQ_DemoState = {
	["Update"] = BBQ_DemoState_type_def:get_field("Update"):get_data(nil),
	["ResultDemoUpdate"] = BBQ_DemoState_type_def:get_field("ResultDemoUpdate"):get_data(nil)
};

local reqDangoLogStart_method = Constants.type_definitions.GuiManager_type_def:get_method("reqDangoLogStart(snow.gui.GuiDangoLog.DangoLogParam, System.Single)");

local kitchenFsm_type_def = Constants.SDK.find_type_definition("snow.gui.fsm.kitchen.GuiKitchenFsmManager");
local get_KitchenCookDemoHandler_method = kitchenFsm_type_def:get_method("get_KitchenCookDemoHandler");
local get_KitchenEatDemoHandler_method = kitchenFsm_type_def:get_method("get_KitchenEatDemoHandler");
local get_KitchenDangoLogParam_method = kitchenFsm_type_def:get_method("get_KitchenDangoLogParam");

local GuiKitchenCookingEventDemoFsmAction_type_def = Constants.SDK.find_type_definition("snow.gui.fsm.kitchen.GuiKitchenCookingEventDemoFsmAction");
local CookingDemoState_field = GuiKitchenCookingEventDemoFsmAction_type_def:get_field("_DemoState");
local CookingDemoState_Demo_Update = CookingDemoState_field:get_type():get_field("Demo_Update"):get_data(nil);

local GuiKitchenEatingEventDemoFsmAction_type_def = Constants.SDK.find_type_definition("snow.gui.fsm.kitchen.GuiKitchenEatingEventDemoFsmAction");
local EatingDemoState_field = GuiKitchenEatingEventDemoFsmAction_type_def:get_field("_DemoState");
local EatingDemoState_Demo_Update = EatingDemoState_field:get_type():get_field("Demo_Update"):get_data(nil);

local reqFinish_method = get_KitchenCookDemoHandler_method:get_return_type():get_method("reqFinish(System.Single)");
-- Auto Dango Ticket
local function PreHook_updateList(args)
	local MealFunc = Constants.SDK.to_managed_object(args[2]);
	if MealFunc ~= nil then
		setMealTicketFlag_method:call(MealFunc, true);
	end
end
Constants.SDK.hook(mealFunc_type_def:get_method("updateList(System.Boolean)"), PreHook_updateList);
-- Skip Dango Song Main Function
--CookDemo
local GuiKitchenFsmManager = nil;

local GuiKitchenCookingEventDemoFsmAction = nil;
local function PreHook_CookingDemoUpdate(args)
	GuiKitchenCookingEventDemoFsmAction = Constants.SDK.to_managed_object(args[2]);
end
local function PostHook_CookingDemoUpdate()
	if GuiKitchenCookingEventDemoFsmAction == nil then
		return;
	end

	if CookingDemoState_field:get_data(GuiKitchenCookingEventDemoFsmAction) == CookingDemoState_Demo_Update then
		GuiKitchenFsmManager = GuiKitchenFsmManager or Constants.SDK.get_managed_singleton("snow.gui.fsm.kitchen.GuiKitchenFsmManager");
		if GuiKitchenFsmManager ~= nil then
			local CookDemoHandler = get_KitchenCookDemoHandler_method:call(GuiKitchenFsmManager);
			if CookDemoHandler ~= nil then
				reqFinish_method:call(CookDemoHandler, 0.0);
			end
		end
	end
	GuiKitchenCookingEventDemoFsmAction = nil;
end
Constants.SDK.hook(GuiKitchenCookingEventDemoFsmAction_type_def:get_method("update(via.behaviortree.ActionArg)"), PreHook_CookingDemoUpdate, PostHook_CookingDemoUpdate);
--EatDemo
local showDangoLog = false;

local GuiKitchenEatingEventDemoFsmAction = nil;
local function PreHook_EatingDemoUpdate(args)
	GuiKitchenEatingEventDemoFsmAction = Constants.SDK.to_managed_object(args[2]);
end
local function PostHook_EatingDemoUpdate()
	if GuiKitchenEatingEventDemoFsmAction == nil then
		return;
	end

	if EatingDemoState_field:get_data(GuiKitchenEatingEventDemoFsmAction) == EatingDemoState_Demo_Update then
		GuiKitchenFsmManager = GuiKitchenFsmManager or Constants.SDK.get_managed_singleton("snow.gui.fsm.kitchen.GuiKitchenFsmManager");
		if GuiKitchenFsmManager ~= nil then
			local EatDemoHandler = get_KitchenEatDemoHandler_method:call(GuiKitchenFsmManager);
			if EatDemoHandler ~= nil then
				reqFinish_method:call(EatDemoHandler, 0.0);
				showDangoLog = true;
			end
		end
	end
	GuiKitchenEatingEventDemoFsmAction = nil;
end
Constants.SDK.hook(GuiKitchenEatingEventDemoFsmAction_type_def:get_method("update(via.behaviortree.ActionArg)"), PreHook_EatingDemoUpdate, PostHook_EatingDemoUpdate);

local function PostHook_requestAutoSaveAll()
	if showDangoLog ~= true then
		return;
	end

	showDangoLog = false;
	GuiKitchenFsmManager = GuiKitchenFsmManager or Constants.SDK.get_managed_singleton("snow.gui.fsm.kitchen.GuiKitchenFsmManager");
	if GuiKitchenFsmManager == nil then
		return;
	end

	local GuiManager = Constants.SDK.get_managed_singleton("snow.gui.GuiManager");
	local KitchenDangoLogParam = get_KitchenDangoLogParam_method:call(GuiKitchenFsmManager);
	if GuiManager ~= nil and KitchenDangoLogParam ~= nil then
		reqDangoLogStart_method:call(GuiManager, KitchenDangoLogParam, 5.0);
	end
	GuiKitchenFsmManager = nil;
end
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.SnowSaveService"):get_method("requestAutoSaveAll"), nil, PostHook_requestAutoSaveAll);
--BBQ
local GuiKitchen_BBQ = nil;
local function PreHook_BBQ_updatePlayDemo(args)
	GuiKitchen_BBQ = Constants.SDK.to_managed_object(args[2]);
end
local function PostHook_BBQ_updatePlayDemo()
	if GuiKitchen_BBQ == nil then
		return;
	end

	local DemoState = getDemoState_method:call(GuiKitchen_BBQ);
	if DemoState == BBQ_DemoState.Update or DemoState == BBQ_DemoState.ResultDemoUpdate then
		local BBQ_DemoHandler = BBQ_DemoHandler_field:get_data(GuiKitchen_BBQ);
		if BBQ_DemoHandler ~= nil then
			reqFinish_method:call(BBQ_DemoHandler, 0.0);
		end
	end
	GuiKitchen_BBQ = nil;
end
Constants.SDK.hook(GuiKitchen_BBQ_type_def:get_method("updatePlayDemo"), PreHook_BBQ_updatePlayDemo, PostHook_BBQ_updatePlayDemo);