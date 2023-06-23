local Constants = require("Constants.Constants");
if not Constants then
	return;
end

local settings = Constants.JSON.load_file("Enhance_Dango_kitchen.json") or {
	skipDangoSong = true,
	skipEating = true,
	skipMotley = true,
	TicketByDefault = true,
};
if settings.skipDangoSong == nil then
	settings.skipDangoSong = true;
end
if settings.skipEating == nil then
	settings.skipEating = true;
end
if settings.skipMotley == nil then
	settings.skipMotley = true;
end
if settings.TicketByDefault == nil then
	settings.TicketByDefault = true;
end
-- VIP Dango Ticket Cache
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
local get_KitchenCookDemoHandler_method = kitchenFsm_type_def:get_method("get_KitchenCookDemoHandler"); -- retval
local get_KitchenEatDemoHandler_method = kitchenFsm_type_def:get_method("get_KitchenEatDemoHandler"); -- retval
local set_IsCookDemoSkip_method = kitchenFsm_type_def:get_method("set_IsCookDemoSkip(System.Boolean)");
local get_KitchenDangoLogParam_method = kitchenFsm_type_def:get_method("get_KitchenDangoLogParam"); -- retval

local reqFinish_method = Constants.SDK.find_type_definition("snow.eventcut.EventcutHandler"):get_method("reqFinish(System.Single)");

local GuiKitchenCookingEventDemoFsmAction_type_def = Constants.SDK.find_type_definition("snow.gui.fsm.kitchen.GuiKitchenCookingEventDemoFsmAction");
local CookingDemoState_field = GuiKitchenCookingEventDemoFsmAction_type_def:get_field("_DemoState");
local CookingDemoState_Demo_Update = CookingDemoState_field:get_type():get_field("Demo_Update"):get_data(nil);

local GuiKitchenEatingEventDemoFsmAction_type_def = Constants.SDK.find_type_definition("snow.gui.fsm.kitchen.GuiKitchenEatingEventDemoFsmAction");
local EatingDemoState_field = GuiKitchenEatingEventDemoFsmAction_type_def:get_field("_DemoState");
local EatingDemoState_Demo_Update = EatingDemoState_field:get_type():get_field("Demo_Update"):get_data(nil);
-- Auto receive Kitchen tickets
local get_Kitchen_method = Constants.SDK.find_type_definition("snow.data.FacilityDataManager"):get_method("get_Kitchen");

local get_BbqFunc_method = get_Kitchen_method:get_return_type():get_method("get_BbqFunc");

local BbqFunc_type_def = get_BbqFunc_method:get_return_type();
local isExistOutputTicket_method = BbqFunc_type_def:get_method("isExistOutputTicket");
local outputTicket_method = BbqFunc_type_def:get_method("outputTicket");
-- VIP Dango Ticket Main Function
local MealFunc = nil;
local function PreHook_updateList(args)
	if settings.TicketByDefault then
		MealFunc = Constants.SDK.to_managed_object(args[2]);
	end
end
local function PostHook_updateList()
	if MealFunc then
		setMealTicketFlag_method:call(MealFunc, true);
	end
	MealFunc = nil;
end
Constants.SDK.hook(mealFunc_type_def:get_method("updateList(System.Boolean)"), PreHook_updateList, PostHook_updateList);
-- Skip Dango Song Main Function
--CookDemo
local GuiKitchenFsmManager = nil;

local GuiKitchenCookingEventDemoFsmAction = nil;
local function PreHook_CookingDemoUpdate(args)
	if settings.skipDangoSong then
		GuiKitchenCookingEventDemoFsmAction = Constants.SDK.to_managed_object(args[2]);
	end
end
local function PostHook_CookingDemoUpdate()
	if GuiKitchenCookingEventDemoFsmAction and CookingDemoState_field:get_data(GuiKitchenCookingEventDemoFsmAction) == CookingDemoState_Demo_Update then
		GuiKitchenFsmManager = GuiKitchenFsmManager or Constants.SDK.get_managed_singleton("snow.gui.fsm.kitchen.GuiKitchenFsmManager");
		if GuiKitchenFsmManager then
			local CookDemoHandler = get_KitchenCookDemoHandler_method:call(GuiKitchenFsmManager);
			if CookDemoHandler then
				reqFinish_method:call(CookDemoHandler, 0.0);
				if not settings.skipEating then
					set_IsCookDemoSkip_method:call(kitchenFsm, true);
					GuiKitchenFsmManager = nil;
				end
			end
		end
	end
	GuiKitchenCookingEventDemoFsmAction = nil;
end
Constants.SDK.hook(GuiKitchenCookingEventDemoFsmAction_type_def:get_method("update(via.behaviortree.ActionArg)"), PreHook_CookingDemoUpdate, PostHook_CookingDemoUpdate);
--EatDemo
local showDangoLog = nil;

local GuiKitchenEatingEventDemoFsmAction = nil;
local function PreHook_EatingDemoUpdate(args)
	if settings.skipEating then
		GuiKitchenEatingEventDemoFsmAction = Constants.SDK.to_managed_object(args[2]);
	end
end
local function PostHook_EatingDemoUpdate()
	if GuiKitchenEatingEventDemoFsmAction and EatingDemoState_field:get_data(GuiKitchenEatingEventDemoFsmAction) == EatingDemoState_Demo_Update then
		GuiKitchenFsmManager = GuiKitchenFsmManager or Constants.SDK.get_managed_singleton("snow.gui.fsm.kitchen.GuiKitchenFsmManager");
		if GuiKitchenFsmManager then
			local EatDemoHandler = get_KitchenEatDemoHandler_method:call(GuiKitchenFsmManager);
			if EatDemoHandler then
				reqFinish_method:call(EatDemoHandler, 0.0);
				showDangoLog = true;
			end
		end
	end
	GuiKitchenEatingEventDemoFsmAction = nil;
end
Constants.SDK.hook(GuiKitchenEatingEventDemoFsmAction_type_def:get_method("update(via.behaviortree.ActionArg)"), PreHook_EatingDemoUpdate, PostHook_EatingDemoUpdate);

local function PostHook_requestAutoSaveAll()
	if showDangoLog then
		showDangoLog = nil;
		local GuiManager = Constants.SDK.get_managed_singleton("snow.gui.GuiManager");
		local KitchenDangoLogParam = get_KitchenDangoLogParam_method:call(GuiKitchenFsmManager);
		if GuiManager and KitchenDangoLogParam then
			reqDangoLogStart_method:call(GuiManager, KitchenDangoLogParam, 5.0);
		end
		GuiKitchenFsmManager = nil;
	end
end
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.SnowSaveService"):get_method("requestAutoSaveAll"), nil, PostHook_requestAutoSaveAll);
--BBQ
local GuiKitchen_BBQ = nil;
local function PreHook_BBQ_updatePlayDemo(args)
	if settings.skipMotley then
		GuiKitchen_BBQ = Constants.SDK.to_managed_object(args[2]);
	end
end
local function PostHook_BBQ_updatePlayDemo()
	if GuiKitchen_BBQ then
		local DemoState = getDemoState_method:call(GuiKitchen_BBQ);
		if DemoState == BBQ_DemoState.Update or DemoState == BBQ_DemoState.ResultDemoUpdate then
			local BBQ_DemoHandler = BBQ_DemoHandler_field:get_data(GuiKitchen_BBQ);
			if BBQ_DemoHandler then
				reqFinish_method:call(BBQ_DemoHandler, 0.0);
			end
		end
	end
	GuiKitchen_BBQ = nil;
end
Constants.SDK.hook(GuiKitchen_BBQ_type_def:get_method("updatePlayDemo"), PreHook_BBQ_updatePlayDemo, PostHook_BBQ_updatePlayDemo);
-- Auto receive Kitchen tickets
local function PostHook_BBQ_doClose()
	local FacilityDataManager = Constants.SDK.get_managed_singleton("snow.data.FacilityDataManager");
	if FacilityDataManager then
		local Kitchen = get_Kitchen_method:call(FacilityDataManager);
		if Kitchen then
			local BbqFunc = get_BbqFunc_method:call(Kitchen);
			if BbqFunc and isExistOutputTicket_method:call(BbqFunc) then
				outputTicket_method:call(BbqFunc);
			end
		end
	end
end
Constants.SDK.hook(GuiKitchen_BBQ_type_def:get_method("doClose"), nil, PostHook_BBQ_doClose);

---- re Callbacks ----
local function save_config()
	Constants.JSON.dump_file("Enhance_Dango_kitchen.json", settings);
end

Constants.RE.on_config_save(save_config);

local isDrawOptionWindow = false;
Constants.RE.on_draw_ui(function()
	if Constants.IMGUI.button("[Enhance Dango Kitchen]") then
		isDrawOptionWindow = true;
	end
	
    if isDrawOptionWindow then
        if Constants.IMGUI.begin_window("[Enhance Dango Kitchen] Options", true, 64) then
			local config_changed = false;
			local changed = false;
			config_changed, settings.skipDangoSong = Constants.IMGUI.checkbox("Skip the song", settings.skipDangoSong);
			changed, settings.skipEating = Constants.IMGUI.checkbox("Skip eating", settings.skipEating);
			config_changed = config_changed or changed;
			changed, settings.skipMotley = Constants.IMGUI.checkbox("Skip Motley Mix", settings.skipMotley);
			config_changed = config_changed or changed;
			Constants.IMGUI.spacing();
			changed, settings.TicketByDefault = Constants.IMGUI.checkbox("Use Dango Ticket as default choice##VIPDango", settings.TicketByDefault);
			config_changed = config_changed or changed;
			Constants.IMGUI.end_window();
			if config_changed then
				save_config();
			end
        else
            isDrawOptionWindow = false;
        end
    end
end);