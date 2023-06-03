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
local get_refGuiDangoLog_method = Constants.type_definitions.GuiManager_type_def:get_method("get_refGuiDangoLog");
local reqDangoLogStart_method = get_refGuiDangoLog_method:get_return_type():get_method("reqDangoLogStart(snow.gui.GuiDangoLog.DangoLogParam, System.Single)");

local kitchenFsm_type_def = Constants.SDK.find_type_definition("snow.gui.fsm.kitchen.GuiKitchenFsmManager");
local set_IsCookDemoSkip_method = kitchenFsm_type_def:get_method("set_IsCookDemoSkip(System.Boolean)");
local get_KitchenDangoLogParam_method = kitchenFsm_type_def:get_method("get_KitchenDangoLogParam");

local EventcutHandler_type_def = Constants.SDK.find_type_definition("snow.eventcut.EventcutHandler");
local get_EventId_method = EventcutHandler_type_def:get_method("get_EventId"); -- retval
local get_LoadState_method = EventcutHandler_type_def:get_method("get_LoadState"); -- retval
local get_Playing_method = EventcutHandler_type_def:get_method("get_Playing"); -- retval
local reqFinish_method = EventcutHandler_type_def:get_method("reqFinish(System.Single)");

local LOADSTATE_ACTIVE = get_LoadState_method:get_return_type():get_field("Active"):get_data(nil);

local EventId_type_def = get_EventId_method:get_return_type();
local cooking_events = {
    [EventId_type_def:get_field("evc3026"):get_data(nil)] = settings.skipDangoSong, --village
    [EventId_type_def:get_field("evc3027"):get_data(nil)] = settings.skipDangoSong, --hub
    [EventId_type_def:get_field("evc3503"):get_data(nil)] = settings.skipDangoSong  --plaza
};
local eating_events = {
    [EventId_type_def:get_field("evc3025"):get_data(nil)] = settings.skipEating, --village
    [EventId_type_def:get_field("evc3024"):get_data(nil)] = settings.skipEating, --hub
    [EventId_type_def:get_field("evc3504"):get_data(nil)] = settings.skipEating  --plaza
};
local bbq_events = {
    [EventId_type_def:get_field("evc3033"):get_data(nil)] = settings.skipMotley, --village
    [EventId_type_def:get_field("evc3034"):get_data(nil)] = settings.skipMotley, --hub
    [EventId_type_def:get_field("evc3505"):get_data(nil)] = settings.skipMotley  --plaza
};

-- VIP Dango Ticket Main Function
local MealFunc = nil;
Constants.SDK.hook(mealFunc_type_def:get_method("updateList(System.Boolean)"), function(args)
	if settings.TicketByDefault then
		MealFunc = Constants.SDK.to_managed_object(args[2]);
	end
end, function()
	if MealFunc then
		setMealTicketFlag_method:call(MealFunc, true);
	end
	MealFunc = nil;
end);

-- Skip Dango Song Main Function
local COOK_DEMO = 1;
local EAT_DEMO = 2;
local BBQ_DEMO = 3;

local DemoHandler = nil;
local DemoType = nil;
Constants.SDK.hook(EventcutHandler_type_def:get_method("play(System.Boolean)"), function(args)
	if settings.skipDangoSong or settings.skipEating or settings.skipMotley then
		DemoHandler = Constants.SDK.to_managed_object(args[2]);
		if DemoHandler then
			local EventId = get_EventId_method:call(DemoHandler);
			if EventId ~= nil then
				DemoType = (cooking_events[EventId] and COOK_DEMO) or (eating_events[EventId] and EAT_DEMO) or (bbq_events[EventId] and BBQ_DEMO) or nil;
			end
			if not DemoType then
				DemoHandler = nil;
			end
		end
	end
end, function()
	if DemoHandler and DemoType then
		if get_LoadState_method:call(DemoHandler) == LOADSTATE_ACTIVE and get_Playing_method:call(DemoHandler) then
			reqFinish_method:call(DemoHandler, 0.0);
			DemoHandler = nil;
			if DemoType ~= EAT_DEMO then
				if DemoType == COOK_DEMO and not settings.skipEating then
					local kitchenFsm = Constants.SDK.get_managed_singleton("snow.gui.fsm.kitchen.GuiKitchenFsmManager");
					if kitchenFsm then
						set_IsCookDemoSkip_method:call(kitchenFsm, true);
					end
				end
				DemoType = nil;
			end
		end
	end
end);

Constants.SDK.hook(Constants.SDK.find_type_definition("snow.SnowSaveService"):get_method("requestAutoSaveAll"), nil, function()
	if DemoType == EAT_DEMO then
		DemoType = nil;
		local GuiManager = Constants.SDK.get_managed_singleton("snow.gui.GuiManager");
		local kitchenFsm = Constants.SDK.get_managed_singleton("snow.gui.fsm.kitchen.GuiKitchenFsmManager");
		if GuiManager and kitchenFsm then
			local GuiDangoLog = get_refGuiDangoLog_method:call(GuiManager);
			local KitchenDangoLogParam = get_KitchenDangoLogParam_method:call(kitchenFsm);
			if GuiDangoLog and KitchenDangoLogParam then
				reqDangoLogStart_method:call(GuiDangoLog, KitchenDangoLogParam, 5.0);
			end
		end
	end
end);

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
		local changed = false;
        if Constants.IMGUI.begin_window("[Enhance Dango Kitchen] Options", true, 64) then
			changed, settings.skipDangoSong = Constants.IMGUI.checkbox("Skip the song", settings.skipDangoSong);
			changed, settings.skipEating = Constants.IMGUI.checkbox("Skip eating", settings.skipEating);
			changed, settings.skipMotley = Constants.IMGUI.checkbox("Skip Motley Mix", settings.skipMotley);
			Constants.IMGUI.spacing();
			changed, settings.TicketByDefault = Constants.IMGUI.checkbox("Use Dango Ticket as default choice##VIPDango", settings.TicketByDefault);
			Constants.IMGUI.end_window();
			if changed then
				save_config();
			end
        else
            isDrawOptionWindow = false;
        end
    end
end);