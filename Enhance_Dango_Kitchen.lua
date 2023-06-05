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
local get_refGuiKichen_BBQ_method = Constants.type_definitions.GuiManager_type_def:get_method("get_refGuiKichen_BBQ"); -- retval
local reqDangoLogStart_method = Constants.type_definitions.GuiManager_type_def:get_method("reqDangoLogStart(snow.gui.GuiDangoLog.DangoLogParam, System.Single)");

local kitchenFsm_type_def = Constants.SDK.find_type_definition("snow.gui.fsm.kitchen.GuiKitchenFsmManager");
local get_KitchenCookDemoHandler_method = kitchenFsm_type_def:get_method("get_KitchenCookDemoHandler"); -- retval
local set_IsCookDemoSkip_method = kitchenFsm_type_def:get_method("set_IsCookDemoSkip(System.Boolean)");
local get_KitchenDangoLogParam_method = kitchenFsm_type_def:get_method("get_KitchenDangoLogParam"); -- retval

local BBQ_DemoHandler_field = get_refGuiKichen_BBQ_method:get_return_type():get_field("_DemoHandler");

local EventcutHandler_type_def = Constants.SDK.find_type_definition("snow.eventcut.EventcutHandler");
local get_LoadState_method = EventcutHandler_type_def:get_method("get_LoadState"); -- retval
local get_Playing_method = EventcutHandler_type_def:get_method("get_Playing"); -- retval
local reqFinish_method = EventcutHandler_type_def:get_method("reqFinish(System.Single)");

local LoadState_ACTIVE = get_LoadState_method:get_return_type():get_field("Active"):get_data(nil);
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
local function PostHook_CookingDemoUpdate()
	if settings.skipDangoSong then
		local kitchenFsm = Constants.SDK.get_managed_singleton("snow.gui.fsm.kitchen.GuiKitchenFsmManager");
		if kitchenFsm then
			local CookDemoHandler = get_KitchenCookDemoHandler_method:call(kitchenFsm);
			if CookDemoHandler and get_LoadState_method:call(CookDemoHandler) == LoadState_ACTIVE and get_Playing_method:call(CookDemoHandler) then
				reqFinish_method:call(CookDemoHandler, 0.0);
				if not settings.skipEating then
					set_IsCookDemoSkip_method:call(kitchenFsm, true);
				end
			end
		end
	end
end
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.kitchen.GuiKitchenCookingEventDemoFsmAction"):get_method("update(via.behaviortree.ActionArg)"), nil, PostHook_CookingDemoUpdate);
--EatDemo
local showDangoLog = nil;
local EatingActionArg = nil;
local function PreHook_EatingDemoUpdate(args)
	if settings.skipEating then
		EatingActionArg = Constants.SDK.to_managed_object(args[3]);
	end
end
local function PostHook_EatingDemoUpdate()
	if EatingActionArg then
		showDangoLog = true;
		Constants.methods.notifyActionEnd_method:call(EatingActionArg);
	end
	EatingActionArg = nil;
end
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.fsm.kitchen.GuiKitchenEatingEventDemoFsmAction"):get_method("update(via.behaviortree.ActionArg)"), PreHook_EatingDemoUpdate, PostHook_EatingDemoUpdate);

local function PostHook_requestAutoSaveAll()
	if showDangoLog then
		showDangoLog = nil;
		local kitchenFsm = Constants.SDK.get_managed_singleton("snow.gui.fsm.kitchen.GuiKitchenFsmManager");
		if kitchenFsm then
			local GuiManager = Constants.SDK.get_managed_singleton("snow.gui.GuiManager");
			local KitchenDangoLogParam = get_KitchenDangoLogParam_method:call(kitchenFsm);
			if GuiManager and KitchenDangoLogParam then
				reqDangoLogStart_method:call(GuiManager, KitchenDangoLogParam, 5.0);
			end
		end
	end
end
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.SnowSaveService"):get_method("requestAutoSaveAll"), nil, PostHook_requestAutoSaveAll);
--BBQ
local GuiKichen_BBQ = nil;
local function PreHook_BBQ_updatePlayDemo(args)
	if settings.skipMotley then
		GuiKichen_BBQ = Constants.SDK.to_managed_object(args[2]);
	end
end
local function PostHook_BBQ_updatePlayDemo()
	if GuiKichen_BBQ then
		local BBQ_DemoHandler = BBQ_DemoHandler_field:get_data(GuiKichen_BBQ);
		if BBQ_DemoHandler and get_LoadState_method:call(BBQ_DemoHandler) == LoadState_ACTIVE and get_Playing_method:call(BBQ_DemoHandler) then
			reqFinish_method:call(BBQ_DemoHandler, 0.0);
		end
	end
	GuiKichen_BBQ = nil;
end
Constants.SDK.hook(Constants.SDK.find_type_definition("snow.gui.GuiKitchen_BBQ"):get_method("updatePlayDemo"), PreHook_BBQ_updatePlayDemo, PostHook_BBQ_updatePlayDemo);

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