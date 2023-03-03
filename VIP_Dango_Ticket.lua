local json = json;
local json_dump_file = nil;
local json_load_file = nil;

local sdk = sdk;
local sdk_hook = sdk.hook;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
local sdk_to_managed_object = sdk.to_managed_object;
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

local ipairs = ipairs;

local config = {};
local configPath = "VIP_Dango_Ticket_Config.json";
local jsonAvailable = json ~= nil;

if jsonAvailable then
	json_dump_file = json.dump_file;
	json_load_file = json.load_file;
    local file = json_load_file(configPath);
	config = file or {InfiniteDangoTickets = false, TicketByDefault = false, ShowAllDango = false, skewerLvs = {4, 3, 1}};
end
if config.InfiniteDangoTickets == nil then
	config.InfiniteDangoTickets = false;
end
if config.TicketByDefault == nil then
	config.TicketByDefault = false;
end
if config.ShowAllDango == nil then
	config.ShowAllDango = false;
end
if config.skewerLvs == nil then
	config.skewerLvs = {4, 3, 1};
end

local function save_config()
	if jsonAvailable then
		json_dump_file(configPath, config);
	end
end

save_config();

local SavedDangoChance = 100;
local SavedDango = nil;
local DangoTicketState = false;
local Param = nil;

local FacilityManager = nil;
local FlagManager = nil;
local DataManager = nil;

local kitchen_field = sdk_find_type_definition("snow.data.FacilityDataManager"):get_field("_Kitchen");
local mealFunc_field = kitchen_field:get_type():get_field("_MealFunc");
local mealFunc_type_def = mealFunc_field:get_type();
local getMealTicketFlag_method = mealFunc_type_def:get_method("getMealTicketFlag");
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

sdk_hook(get_SkillActiveRate_method,--force 100% activation
function(args)
	if not FacilityManager or FacilityManager:get_reference_count() <= 1 then
		FacilityManager = sdk_get_managed_singleton("snow.data.FacilityDataManager");
	end
	if FacilityManager then
		DangoTicketState = getMealTicketFlag_method:call(mealFunc_field:get_data(kitchen_field:get_data(FacilityManager)));
		if DangoTicketState then
			SavedDango = sdk_to_managed_object(args[2]);
			Param = dangoData_param_field:get_data(SavedDango);
			SavedDangoChance = skillActiveRate_field:get_data(Param);
			Param:set_field("_SkillActiveRate", 100);
		end
	end
end,
function(retval)
	if DangoTicketState then
		Param:set_field("_SkillActiveRate", SavedDangoChance);
	end
	Param = nil;
	return retval;
end);

sdk_hook(setDangoDetailWindow_method,--inform Gui of Dango Lv changes
function(args)
	for i = 0, 2, 1 do
		local newSkewerLv = sdk_create_instance("System.UInt32");
		newSkewerLv:set_field("mValue", config.skewerLvs[i + 1]);
		guiKitchen_SpecialSkewerDangoLv_set_Item_method:call(guiKitchen_SpecialSkewerDangoLv_field:get_data(sdk_to_managed_object(args[2])), i, newSkewerLv);
	end
end);

sdk_hook(updateList_method,--inform Dango order constructor of Dango Lv changes
function(args)
	if not FacilityManager or FacilityManager:get_reference_count() <= 1 then
		FacilityManager = sdk_get_managed_singleton("snow.data.FacilityDataManager");
	end
	if FacilityManager then
		local KitchenMealFunc = mealFunc_field:get_data(kitchen_field:get_data(FacilityManager));
		if config.TicketByDefault then
			setMealTicketFlag_method:call(KitchenMealFunc, true);
		end
		for i = 0, 2, 1 do
			local newSkewerLv = sdk_create_instance("System.UInt32");
			newSkewerLv:set_field("mValue", config.skewerLvs[i + 1]);
			mealFunc_SpecialSkewerDangoLv_set_Item_method:call(mealFunc_SpecialSkewerDangoLv_field:get_data(KitchenMealFunc), i, newSkewerLv);
		end
	end
end,
function(retval)
	if config.ShowAllDango then
		if not FacilityManager or FacilityManager:get_reference_count() <= 1 then
			FacilityManager = sdk_get_managed_singleton("snow.data.FacilityDataManager");
		end
		if not FlagManager or FlagManager:get_reference_count() <= 1 then
			FlagManager = sdk_get_managed_singleton("snow.data.FlagDataManager");
		end
		if FacilityManager and FlagManager then
			for i, dango in ipairs(dangoDataList_ToArray_method:call(dangoDataList_field:get_data(mealFunc_field:get_data(kitchen_field:get_data(FacilityManager))))) do
				local param_data = dangoData_param_field:get_data(dango);
				if isUnlocked_method:call(FlagManager, param_Id_field:get_data(param_data)) then
					param_data:set_field("_DailyRate", 0);
				end
			end
		end
	end
	return retval;
end);

sdk_hook(order_method, nil,
function(retval)
	if config.InfiniteDangoTickets then
		if not DataManager or DataManager:get_reference_count() <= 1 then
			DataManager = sdk_get_managed_singleton("snow.data.DataManager");
		end
		if DataManager then
			tryAddGameItem_method:call(plItemBox_field:get_data(DataManager), 68157564, 1);
		end
	end
	return retval;
end);

local function intSlider(label, index1, index2, min, max)
	local changed, value = imgui_slider_int(label, config[index1][index2], min, max);
	if changed then
		config[index1][index2] = value;
		save_config();
	end
end

re_on_draw_ui(function()
	if imgui_button("[VIP Dango Ticket]") then
		drawDangoTicketOptionsWindow = true;
	end
	
    if drawDangoTicketOptionsWindow then
        if imgui_begin_window("[VIP Dango Ticket] Options", true, 64) then
			local changed = false;
			changed, config.InfiniteDangoTickets = imgui_checkbox('Get Dango Ticket back after use##VIPDango', config.InfiniteDangoTickets);
			changed, config.TicketByDefault = imgui_checkbox('Use Dango Ticket as default choice##VIPDango', config.TicketByDefault);
			changed, config.ShowAllDango = imgui_checkbox('Show all available Dango (including Daily Dango)##VIPDango', config.ShowAllDango);
			imgui_text("Note: To toggle OFF requires game restart after.");
			if imgui_tree_node("Configure Hopping Skewer Dango Levels") then
				intSlider("Top Dango##VIPDango", "skewerLvs", 1, 1, 4);
				intSlider("Mid Dango##VIPDango", "skewerLvs", 2, 1, 4);
				intSlider("Bot Dango##VIPDango", "skewerLvs", 3, 1, 4);
				if imgui_button("Reset to Defaults##VIPDango") then
					config.skewerLvs = {4, 3, 1};
				end
				imgui_tree_pop();
			end
			if changed == true then
				if not config.InfiniteDangoTickets then
					DataManager = nil;
				end
				if not config.TicketByDefault and not config.ShowAllDango then
					FacilityManager = nil;
					FlagManager = nil;
				end
				save_config();
			end
			imgui_end_window();
        else
            drawDangoTicketOptionsWindow = false;
        end
    end
end);

re_on_config_save(save_config);