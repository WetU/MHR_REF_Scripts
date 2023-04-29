-- Initialize
local json = json;
local jsonAvailable = json ~= nil;
local json_load_file = jsonAvailable and json.load_file or nil;
local json_dump_file = jsonAvailable and json.dump_file or nil;

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
if json_load_file then
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
local get_DangoDataList_method = mealFunc_type_def:get_method("get_DangoDataList");
local mealFunc_SpecialSkewerDangoLv_field = mealFunc_type_def:get_field("SpecialSkewerDangoLv");

local DangoDataList_type_def = get_DangoDataList_method:get_return_type();
local DangoDataList_get_Count_method = DangoDataList_type_def:get_method("get_Count");
local DangoDataList_get_Item_method = DangoDataList_type_def:get_method("get_Item(System.Int32)");

local mealFunc_SpecialSkewerDangoLv_set_Item_method = mealFunc_SpecialSkewerDangoLv_field:get_type():get_method("set_Item(System.Int32, System.Object)");

local dangoData_type_def = DangoDataList_get_Item_method:get_return_type();
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

local dangoTicket_Item_Id = sdk_find_type_definition("snow.data.ContentsIdSystem.ItemId"):get_field("I_Normal_0124"):get_data(nil);
-- Skip Dango Song cache
local requestAutoSaveAll_method = sdk_find_type_definition("snow.SnowSaveService"):get_method("requestAutoSaveAll");

local GuiDangoLog_field = sdk_find_type_definition("snow.gui.GuiManager"):get_field("<refGuiDangoLog>k__BackingField");
local reqDangoLogStart_method = GuiDangoLog_field:get_type():get_method("reqDangoLogStart(snow.gui.GuiDangoLog.DangoLogParam, System.Single)");

local kitchenFsm_type_def = sdk_find_type_definition("snow.gui.fsm.kitchen.GuiKitchenFsmManager");
local set_IsCookDemoSkip_method = kitchenFsm_type_def:get_method("set_IsCookDemoSkip(System.Boolean)");
local KitchenDangoLogParam_field = kitchenFsm_type_def:get_field("<KitchenDangoLogParam>k__BackingField");

local EventcutHandler_type_def = sdk_find_type_definition("snow.eventcut.EventcutHandler");
local play_method = EventcutHandler_type_def:get_method("play(System.Boolean)");
local get_EventId_method = EventcutHandler_type_def:get_method("get_EventId");
local get_LoadState_method = EventcutHandler_type_def:get_method("get_LoadState");
local get_Playing_method = EventcutHandler_type_def:get_method("get_Playing");
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
local SavedDangoChance = nil;
local Param = nil;
sdk_hook(get_SkillActiveRate_method, function(args)
	if settings.SkillAlwaysActive then
		local dangoData = sdk_to_managed_object(args[2]);
		if dangoData then
			Param = dangoData_param_field:get_data(dangoData);
			if Param then
				SavedDangoChance = skillActiveRate_field:get_data(Param);
				Param:set_field("_SkillActiveRate", 100);
			end
		end
	end
	return sdk_CALL_ORIGINAL;
end, function(retval)
	if SavedDangoChance ~= nil then
		Param:set_field("_SkillActiveRate", SavedDangoChance);
	end
	Param = nil;
	SavedDangoChance = nil;
	return retval;
end);

sdk_hook(setDangoDetailWindow_method, function(args)
	if settings.EnableSkewerLv then
		local guiKitchen = sdk_to_managed_object(args[2]);
		if guiKitchen then
			local guiKitchen_SpecialSkewerDangoLv = guiKitchen_SpecialSkewerDangoLv_field:get_data(guiKitchen);
			if guiKitchen_SpecialSkewerDangoLv then
				for i = 0, 2, 1 do
					local newSkewerLv = sdk_create_instance("System.UInt32");
					newSkewerLv:set_field("mValue", settings.skewerLvs[i + 1]);
					guiKitchen_SpecialSkewerDangoLv_set_Item_method:call(guiKitchen_SpecialSkewerDangoLv, i, newSkewerLv);
				end
			end
		end
	end
	return sdk_CALL_ORIGINAL;
end);

sdk_hook(updateList_method, function(args)
	if settings.TicketByDefault or settings.EnableSkewerLv then
		local FacilityDataManager = sdk_get_managed_singleton("snow.data.FacilityDataManager");
		if FacilityDataManager then
			local Kitchen = kitchen_field:get_data(FacilityDataManager);
			if Kitchen then
				local mealFunc = mealFunc_field:get_data(Kitchen);
				if mealFunc then
					if settings.TicketByDefault then
						setMealTicketFlag_method:call(mealFunc, true);
					end
					if settings.EnableSkewerLv then
						local mealFunc_SpecialSkewerDangoLv = mealFunc_SpecialSkewerDangoLv_field:get_data(mealFunc);
						if mealFunc_SpecialSkewerDangoLv then
							for i = 0, 2, 1 do
								local newSkewerLv = sdk_create_instance("System.UInt32");
								newSkewerLv:set_field("mValue", settings.skewerLvs[i + 1]);
								mealFunc_SpecialSkewerDangoLv_set_Item_method:call(mealFunc_SpecialSkewerDangoLv, i, newSkewerLv);
							end
						end
					end
				end
			end
		end
	end
	return sdk_CALL_ORIGINAL;
end, function(retval)
	if settings.ShowAllDango then
		local FacilityDataManager = sdk_get_managed_singleton("snow.data.FacilityDataManager");
		if FacilityDataManager then
			local Kitchen = kitchen_field:get_data(FacilityDataManager);
			if Kitchen then
				local mealFunc = mealFunc_field:get_data(Kitchen);
				if mealFunc then
					local DangoDataList = get_DangoDataList_method:call(mealFunc);
					if DangoDataList then
						local DangoDataList_count = DangoDataList_get_Count_method:call(DangoDataList);
						if DangoDataList_count >= 0 then
							local FlagManager = sdk_get_managed_singleton("snow.data.FlagDataManager");
							if FlagManager then
								for i = 0, DangoDataList_count - 1, 1 do
									local dango = DangoDataList_get_Item_method:call(DangoDataList, i);
									if dango then
										local param_data = dangoData_param_field:get_data(dango);
										if param_data then
											local param_Id = param_Id_field:get_data(param_data);
											if param_Id and isUnlocked_method:call(FlagManager, param_Id) then
												param_data:set_field("_DailyRate", 0);
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
	return retval;
end);

sdk_hook(order_method, nil, function(retval)
	if settings.InfiniteDangoTickets then
		local DataManager = sdk_get_managed_singleton("snow.data.DataManager");
		if DataManager then
			local plItemBox = plItemBox_field:get_data(DataManager);
			if plItemBox then
				tryAddGameItem_method:call(plItemBox, dangoTicket_Item_Id, 1);
			end
		end
	end
	return retval;
end);

-- Skip Dango Song Main Function
local DemoHandler = nil;
local DemoType = nil;  -- 1 = Cook, 2 = Eating, 3 = BBQ;
sdk_hook(play_method, function(args)
	if settings.skipDangoSong or settings.skipEating or settings.skipMotley then
		DemoHandler = sdk_to_managed_object(args[2]);
		if DemoHandler then
			local EventId = get_EventId_method:call(DemoHandler);
			if EventId then
				DemoType = (cooking_events[EventId] and 1) or (eating_events[EventId] and 2) or (bbq_events[EventId] and 3) or nil;
			end
			if not DemoType then
				DemoHandler = nil;
			end
		end
	end
	return sdk_CALL_ORIGINAL;
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
	if json_dump_file then
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
		local changed = false;
        if imgui_begin_window("[Enhance Dango Kitchen] Options", true, 64) then
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
			imgui_end_window();
        else
            isDrawOptionWindow = false;
			if changed then
				save_config();
			end
        end
    end
end);