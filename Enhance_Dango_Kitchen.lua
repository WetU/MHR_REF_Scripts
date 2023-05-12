-- Initialize
local json = json;
local json_load_file = json.load_file;
local json_dump_file = json.dump_file;

local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
local sdk_to_managed_object = sdk.to_managed_object;
local sdk_hook = sdk.hook;

local re = re;
local re_on_draw_ui = re.on_draw_ui;
local re_on_config_save = re.on_config_save;

local imgui = imgui;
local imgui_button = imgui.button;
local imgui_begin_window = imgui.begin_window;
local imgui_checkbox = imgui.checkbox;
local imgui_text = imgui.text;
local imgui_tree_node = imgui.tree_node;
local imgui_tree_pop = imgui.tree_pop;
local imgui_end_window = imgui.end_window;
local imgui_spacing = imgui.spacing;

local settings = json_load_file("Enhance_Dango_kitchen.json") or {
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
local mealFunc_type_def = sdk_find_type_definition("snow.facility.kitchen.MealFunc");
local updateList_method = mealFunc_type_def:get_method("updateList(System.Boolean)");
local setMealTicketFlag_method = mealFunc_type_def:get_method("setMealTicketFlag(System.Boolean)");
-- Skip Dango Song cache
local requestAutoSaveAll_method = sdk_find_type_definition("snow.SnowSaveService"):get_method("requestAutoSaveAll");

local GuiDangoLog_field = sdk_find_type_definition("snow.gui.GuiManager"):get_field("<refGuiDangoLog>k__BackingField");
local reqDangoLogStart_method = GuiDangoLog_field:get_type():get_method("reqDangoLogStart(snow.gui.GuiDangoLog.DangoLogParam, System.Single)");

local kitchenFsm_type_def = sdk_find_type_definition("snow.gui.fsm.kitchen.GuiKitchenFsmManager");
local set_IsCookDemoSkip_method = kitchenFsm_type_def:get_method("set_IsCookDemoSkip(System.Boolean)");
local KitchenDangoLogParam_field = kitchenFsm_type_def:get_field("<KitchenDangoLogParam>k__BackingField");

local EventcutHandler_type_def = sdk_find_type_definition("snow.eventcut.EventcutHandler");
local play_method = EventcutHandler_type_def:get_method("play(System.Boolean)");
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
sdk_hook(updateList_method, function(args)
	if settings.TicketByDefault then
		local mealFunc = sdk_to_managed_object(args[2]);
		if mealFunc then
			setMealTicketFlag_method:call(mealFunc, true);
		end
	end
end);

-- Skip Dango Song Main Function
local DemoHandler = nil;
local DemoType = nil;  -- 1 = Cook, 2 = Eating, 3 = BBQ;
sdk_hook(play_method, function(args)
	if settings.skipDangoSong or settings.skipEating or settings.skipMotley then
		DemoHandler = sdk_to_managed_object(args[2]);
		if DemoHandler then
			local EventId = get_EventId_method:call(DemoHandler);
			if EventId ~= nil then
				DemoType = (cooking_events[EventId] and 1) or (eating_events[EventId] and 2) or (bbq_events[EventId] and 3) or nil;
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
			if DemoType ~= 2 then
				if DemoType == 1 and not settings.skipEating then
					local kitchenFsm = sdk_get_managed_singleton("snow.gui.fsm.kitchen.GuiKitchenFsmManager");
					if kitchenFsm ~= nil then
						set_IsCookDemoSkip_method:call(kitchenFsm, true);
					end
				end
				DemoType = nil;
			end
		end
	end
end);

sdk_hook(requestAutoSaveAll_method, nil, function()
	if DemoType == 2 then
		DemoType = nil;
		local GuiManager = sdk_get_managed_singleton("snow.gui.GuiManager");
		local kitchenFsm = sdk_get_managed_singleton("snow.gui.fsm.kitchen.GuiKitchenFsmManager");
		if GuiManager and kitchenFsm then
			local GuiDangoLog = GuiDangoLog_field:get_data(GuiManager);
			local KitchenDangoLogParam = KitchenDangoLogParam_field:get_data(kitchenFsm);
			if GuiDangoLog and KitchenDangoLogParam then
				reqDangoLogStart_method:call(GuiDangoLog, KitchenDangoLogParam, 5.0);
			end
		end
	end
end);

---- re Callbacks ----
local function save_config()
	json_dump_file("Enhance_Dango_kitchen.json", settings);
end

re_on_config_save(save_config);

local isDrawOptionWindow = false;
re_on_draw_ui(function()
	if imgui_button("[Enhance Dango Kitchen]") then
		isDrawOptionWindow = true;
	end
	
    if isDrawOptionWindow then
		local changed = false;
        if imgui_begin_window("[Enhance Dango Kitchen] Options", true, 64) then
			changed, settings.skipDangoSong = imgui_checkbox("Skip the song", settings.skipDangoSong);
			changed, settings.skipEating = imgui_checkbox("Skip eating", settings.skipEating);
			changed, settings.skipMotley = imgui_checkbox("Skip Motley Mix", settings.skipMotley);
			imgui_spacing();
			changed, settings.TicketByDefault = imgui_checkbox("Use Dango Ticket as default choice##VIPDango", settings.TicketByDefault);
			imgui_end_window();
			if changed then
				save_config();
			end
        else
            isDrawOptionWindow = false;
        end
    end
end);