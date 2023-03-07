-- Initialize
local json = json;
local json_dump_file = nil;
local json_load_file = nil;

local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
local sdk_to_managed_object = sdk.to_managed_object;
local sdk_hook = sdk.hook;
local sdk_CALL_ORIGINAL = sdk.PreHookResult.CALL_ORIGINAL;
local sdk_create_instance = sdk.create_instance;

local re = re;
local re_on_draw_ui = re.on_draw_ui;
local re_on_config_save = re.on_config_save;

local imgui = imgui;
local imgui_slider_int = imgui.slider_int;
local imgui_button = imgui.button;
local imgui_begin_window = imgui.begin_window;
local imgui_checkbox = imgui.checkbox;
local imgui_text = imgui.text;
local imgui_tree_node = imgui.tree_node;
local imgui_tree_pop = imgui.tree_pop;
local imgui_end_window = imgui.end_window;
local imgui_spacing = imgui.spacing;

local pairs = pairs;

local settings = {};
local jsonAvailable = json ~= nil;

if jsonAvailable then
	json_dump_file = json.dump_file;
	json_load_file = json.load_file;
	local savedConfig = json_load_file("Enhance_Dango_kitchen.json");
	settings = savedConfig or {skipDangoSong = true, skipEating = true, skipMotley = true, InfiniteDangoTickets = false, ShowAllDango = false, TicketByDefault = true, SkillAlwaysActive = false, EnableSkewerLv = false, skewerLvs = {4, 3, 1}};
end
if settings.skipDangoSong == nil then
	settings.skipDangoSong = true;
end
if settings.skipEating == nil then
	settings.skipEating = true;
end
if settings.skipMotley == nil then
	settings.skipMotley = true;
end
if settings.InfiniteDangoTickets == nil then
	settings.InfiniteDangoTickets = false;
end
if settings.ShowAllDango == nil then
	settings.ShowAllDango = false;
end
if settings.TicketByDefault == nil then
	settings.TicketByDefault = true;
end
if settings.SkillAlwaysActive == nil then
	settings.SkillAlwaysActive = false;
end
if settings.EnableSkewerLv == nil then
	settings.EnableSkewerLv = false;
end
if settings.skewerLvs == nil then
	settings.skewerLvs = {4, 3, 1};
end
-- VIP Dango Ticket Cache
local kitchen_field = sdk_find_type_definition("snow.data.FacilityDataManager"):get_field("_Kitchen");
local mealFunc_field = kitchen_field:get_type():get_field("_MealFunc");
local mealFunc_type_def = mealFunc_field:get_type();
local updateList_method = mealFunc_type_def:get_method("updateList");
local setMealTicketFlag_method = mealFunc_type_def:get_method("setMealTicketFlag(System.Boolean)");
local order_method = mealFunc_type_def:get_method("order");

local dangoDataList_field = mealFunc_type_def:get_field("<DangoDataList>k__BackingField");
local dangoDataList_ToArray_method = dangoDataList_field:get_type():get_method("ToArray");

local mealFunc_SpecialSkewerDangoLv_field = mealFunc_type_def:get_field("SpecialSkewerDangoLv");
local mealFunc_SpecialSkewerDangoLv_set_Item_method = mealFunc_SpecialSkewerDangoLv_field:get_type():get_method("set_Item(System.Int32, System.Object)");

local dangoData_type_def = sdk_find_type_definition("snow.data.DangoData");
local get_SkillActiveRate_method = dangoData_type_def:get_method("get_SkillActiveRate");
local dangoData_param_field = dangoData_type_def:get_field("_Param");
local dangoData_param_field_type_def = dangoData_param_field:get_type();
local skillActiveRate_field = dangoData_param_field_type_def:get_field("_SkillActiveRate");
local param_Id_field = dangoData_param_field_type_def:get_field("_Id");

local guiKitchen_type_def = sdk_find_type_definition("snow.gui.fsm.kitchen.GuiKitchen");
local setDangoDetailWindow_method = guiKitchen_type_def:get_method("setDangoDetailWindow");
local guiKitchen_SpecialSkewerDangoLv_field = guiKitchen_type_def:get_field("SpecialSkewerDangoLv");
local guiKitchen_SpecialSkewerDangoLv_set_Item_method = guiKitchen_SpecialSkewerDangoLv_field:get_type():get_method("set_Item(System.Int32, System.Object)");

local isUnlocked_method = sdk_find_type_definition("snow.data.FlagDataManager"):get_method("isUnlocked(snow.data.DataDef.DangoId)");
local plItemBox_field = sdk_find_type_definition("snow.data.DataManager"):get_field("_PlItemBox");
local tryAddGameItem_method = plItemBox_field:get_type():get_method("tryAddGameItem(snow.data.ContentsIdSystem.ItemId, System.Int32)");
-- Skip Dango Song cache
local requestAutoSaveAll_method = sdk_find_type_definition("snow.SnowSaveService"):get_method("requestAutoSaveAll");

local GuiDangoLog_field = sdk_find_type_definition("snow.gui.GuiManager"):get_field("<refGuiDangoLog>k__BackingField");
local GuiDangoLog_type_def = GuiDangoLog_field:get_type();
local reqDangoLogStart_method = GuiDangoLog_type_def:get_method("reqDangoLogStart(snow.gui.GuiDangoLog.DangoLogParam, System.Single)");

local kitchenFsm_type_def = sdk_find_type_definition("snow.gui.fsm.kitchen.GuiKitchenFsmManager");
local set_IsCookDemoSkip_method = kitchenFsm_type_def:get_method("set_IsCookDemoSkip(System.Boolean)");
local KitchenDangoLogParam_field = kitchenFsm_type_def:get_field("<KitchenDangoLogParam>k__BackingField");

local EventcutHandler_type_def = sdk_find_type_definition("snow.eventcut.EventcutHandler");
local play_method = EventcutHandler_type_def:get_method("play(System.Boolean)");
local get_EventId_method = EventcutHandler_type_def:get_method("get_EventId");
local get_LoadState_method = EventcutHandler_type_def:get_method("get_LoadState");
local get_Playing_method = EventcutHandler_type_def:get_method("get_Playing");
local reqFinish_method = EventcutHandler_type_def:get_method("reqFinish(System.Single)");

local LOADSTATE_ACTIVE = sdk_find_type_definition("snow.eventcut.LoadState"):get_field("Active"):get_data(nil);

local EventId_type_def = sdk_find_type_definition("snow.eventcut.EventId");
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
local SavedDangoChance = nil;
local Param = nil;

local FacilityManager = nil;
local FlagManager = nil;
local DataManager = nil;

sdk_hook(get_SkillActiveRate_method, function(args)
	if settings.SkillAlwaysActive then
		Param = dangoData_param_field:get_data(sdk_to_managed_object(args[2]));
		SavedDangoChance = skillActiveRate_field:get_data(Param);
		Param:set_field("_SkillActiveRate", 100);
	end
end, function(retval)
	if Param and SavedDangoChance then
		Param:set_field("_SkillActiveRate", SavedDangoChance);
	end
	Param = nil;
	SavedDangoChance = nil;
	return retval;
end);

sdk_hook(setDangoDetailWindow_method, function(args)
	if settings.EnableSkewerLv then
		for i = 0, 2, 1 do
			local newSkewerLv = sdk_create_instance("System.UInt32");
			newSkewerLv:set_field("mValue", settings.skewerLvs[i + 1]);
			guiKitchen_SpecialSkewerDangoLv_set_Item_method:call(guiKitchen_SpecialSkewerDangoLv_field:get_data(sdk_to_managed_object(args[2])), i, newSkewerLv);
		end
	end
end);

sdk_hook(updateList_method, function(args)
	if not settings.TicketByDefault and not settings.EnableSkewerLv then
		return;
	end
	if not FacilityManager or FacilityManager:get_reference_count() <= 1 then
		FacilityManager = sdk_get_managed_singleton("snow.data.FacilityDataManager");
	end
	if FacilityManager then
		local KitchenMealFunc = mealFunc_field:get_data(kitchen_field:get_data(FacilityManager));
		if KitchenMealFunc then
			if settings.TicketByDefault then
				setMealTicketFlag_method:call(KitchenMealFunc, true);
			end
			if settings.EnableSkewerLv then
				for i = 0, 2, 1 do
					local newSkewerLv = sdk_create_instance("System.UInt32");
					newSkewerLv:set_field("mValue", settings.skewerLvs[i + 1]);
					mealFunc_SpecialSkewerDangoLv_set_Item_method:call(mealFunc_SpecialSkewerDangoLv_field:get_data(KitchenMealFunc), i, newSkewerLv);
				end
			end
		end
	end
end, function(retval)
	if settings.ShowAllDango then
		if not FacilityManager or FacilityManager:get_reference_count() <= 1 then
			FacilityManager = sdk_get_managed_singleton("snow.data.FacilityDataManager");
		end
		if not FlagManager or FlagManager:get_reference_count() <= 1 then
			FlagManager = sdk_get_managed_singleton("snow.data.FlagDataManager");
		end
		if FacilityManager and FlagManager then
			for _, dango in pairs(dangoDataList_ToArray_method:call(dangoDataList_field:get_data(mealFunc_field:get_data(kitchen_field:get_data(FacilityManager))))) do
				local param_data = dangoData_param_field:get_data(dango);
				if isUnlocked_method:call(FlagManager, param_Id_field:get_data(param_data)) then
					param_data:set_field("_DailyRate", 0);
				end
			end
		end
	end
	return retval;
end);

sdk_hook(order_method, nil, function(retval)
	if settings.InfiniteDangoTickets then
		if not DataManager or DataManager:get_reference_count() <= 1 then
			DataManager = sdk_get_managed_singleton("snow.data.DataManager");
		end
		if DataManager then
			tryAddGameItem_method:call(plItemBox_field:get_data(DataManager), 68157564, 1);
		end
	end
	return retval;
end);

-- Skip Dango Song Main Function
local GuiManager = nil;
local GuiDangoLog = nil;

local DemoHandler = nil;
local DemoHandlerType = nil;  -- 1 = Cook, 2 = Eating, 3 = BBQ;
sdk_hook(play_method, function(args)
	if settings.skipDangoSong or settings.skipEating or settings.skipMotley then
		DemoHandler = sdk_to_managed_object(args[2]);
		if DemoHandler then
			local EventId = get_EventId_method:call(DemoHandler);
			if EventId then
				DemoHandlerType = (cooking_events[EventId] and 1) or (eating_events[EventId] and 2) or (bbq_events[EventId] and 3) or nil;
			end
			if not DemoHandlerType then
				DemoHandler = nil;
			end
		end
	end
	return sdk_CALL_ORIGINAL;
end, function()
	if DemoHandler and DemoHandlerType then
		if get_LoadState_method:call(DemoHandler) == LOADSTATE_ACTIVE and get_Playing_method:call(DemoHandler) then
			reqFinish_method:call(DemoHandler, 0.0);
			DemoHandler = nil;
			if DemoHandlerType == 1 then
				DemoHandlerType = nil;
				if not settings.skipEating then
					local kitchenFsm = sdk_get_managed_singleton("snow.gui.fsm.kitchen.GuiKitchenFsmManager");
					if kitchenFsm ~= nil then
						set_IsCookDemoSkip_method:call(kitchenFsm, true);
					end
				end
			elseif DemoHandlerType == 3 then
				DemoHandlerType = nil;
			end
		end
	end
end);

local KitchenDangoLogParam = nil;
sdk_hook(requestAutoSaveAll_method, function()
	if DemoHandlerType == 2 then
		DemoHandlerType = nil;
		local kitchenFsm = sdk_get_managed_singleton("snow.gui.fsm.kitchen.GuiKitchenFsmManager");
		if not GuiDangoLog or GuiDangoLog:get_reference_count() <= 1 then
			if not GuiManager or GuiManager:get_reference_count() <= 1 then
				GuiManager = sdk_get_managed_singleton("snow.gui.GuiManager");
			end
			if GuiManager then
				GuiDangoLog = GuiDangoLog_field:get_data(GuiManager);
			end
		end
		if kitchenFsm then
			KitchenDangoLogParam = KitchenDangoLogParam_field:get_data(kitchenFsm);
		end
	end
end, function()
	if GuiDangoLog and KitchenDangoLogParam then
		reqDangoLogStart_method:call(GuiDangoLog, KitchenDangoLogParam, 5.0);
	end
	KitchenDangoLogParam = nil;
end);
---- re Callbacks ----
local function save_config()
	if jsonAvailable then
		json_dump_file("Enhance_Dango_kitchen.json", settings);
	end
end

re_on_config_save(save_config);

local function intSlider(label, index1, min, max)
	local changed, value = imgui_slider_int(label, settings["skewerLvs"][index1], min, max);
	if changed then
		settings["skewerLvs"][index1] = value;
		save_config();
	end
end

local isDrawOptionWindow = false;
re_on_draw_ui(function()
	if imgui_button("[Enhance Dango Kitchen]") then
		isDrawOptionWindow = true;
	end
	
    if isDrawOptionWindow then
        if imgui_begin_window("[Enhance Dango Kitchen] Options", true, 64) then
			local changed = false;
			changed, settings.skipDangoSong = imgui_checkbox("Skip the song", settings.skipDangoSong);
			changed, settings.skipEating = imgui_checkbox("Skip eating", settings.skipEating);
			changed, settings.skipMotley = imgui_checkbox("Skip Motley Mix", settings.skipMotley);
			imgui_spacing();
			changed, settings.InfiniteDangoTickets = imgui_checkbox("Get Dango Ticket back after use##VIPDango", settings.InfiniteDangoTickets);
			changed, settings.TicketByDefault = imgui_checkbox("Use Dango Ticket as default choice##VIPDango", settings.TicketByDefault);
			changed, settings.ShowAllDango = imgui_checkbox("Show all available Dango (including Daily Dango)##VIPDango", settings.ShowAllDango);
			changed, settings.SkillAlwaysActive = imgui_checkbox("Dango skills always activation", settings.SkillAlwaysActive);
			imgui_spacing();
			changed, settings.EnableSkewerLv = imgui_checkbox("Override Dango Skewer Levels", settings.EnableSkewerLv);
			imgui_text("Note: To toggle OFF requires game restart after.");
			if settings.EnableSkewerLv then
				if imgui_tree_node("Configure Hopping Skewer Dango Levels") then
					intSlider("Top Dango##VIPDango", 1, 1, 4);
					intSlider("Mid Dango##VIPDango", 2, 1, 4);
					intSlider("Bot Dango##VIPDango", 3, 1, 4);
					if imgui_button("Reset to Defaults##VIPDango") then
						settings.skewerLvs = {4, 3, 1};
					end
					imgui_tree_pop();
				end
			end
			if changed then
				if not settings.skipDangoSong and not settings.skipEating and not settings.skipMotley then
					GuiManager = nil;
					GuiDangoLog = nil;
				end
				if not settings.SkillAlwaysActive then
					SavedDangoChance = nil;
					Param = nil;
				end
				if not settings.InfiniteDangoTickets then
					DataManager = nil;
				end
				if not settings.ShowAllDango then
					FlagManager = nil;
					if not settings.TicketByDefault and not settings.EnableSkewerLv then
						FacilityManager = nil;
					end
				end
				save_config();
			end
			imgui_end_window();
        else
            isDrawOptionWindow = false;
        end
    end
end);