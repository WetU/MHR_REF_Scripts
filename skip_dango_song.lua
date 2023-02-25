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

local re = re;
local re_on_frame = re.on_frame;
local re_on_draw_ui = re.on_draw_ui;
local re_on_config_save = re.on_config_save;

local imgui = imgui;
local imgui_tree_node = imgui.tree_node;
local imgui_tree_pop = imgui.tree_pop;
local imgui_checkbox = imgui.checkbox;
local imgui_text = imgui.text;

local log = log;
local log_info = log.info;

local pcall = pcall;
local error = error;

local settings = {};
local jsonAvailable = json ~= nil;

if jsonAvailable == true then
	json_dump_file = json.dump_file;
	json_load_file = json.load_file;
	local savedConfig = json_load_file("Skip_Dango_Song.json");
	settings = savedConfig ~= nil and savedConfig or {skipDangoSong = true, skipEating = true, skipMotley = true};
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
-- Cache
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

local LoadState_type_def = sdk_find_type_definition("snow.eventcut.LoadState");
local LOADSTATE_ACTIVE = LoadState_type_def:get_field("Active"):get_data(nil);
local LOADSTATE_UNLOADED = LoadState_type_def:get_field("Unloaded"):get_data(nil);

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
-- Main Function
local DemoHandler = nil;
local DemoHandlerType = nil;  -- 1 = Cook, 2 = Eating, 3 = BBQ;
local isRunning = false;
sdk_hook(play_method, function(args)
	if settings.skipDangoSong == true or settings.skipEating == true or settings.skipMotley == true then
		DemoHandler = sdk_to_managed_object(args[2]);
		if DemoHandler ~= nil then
			local EventId = get_EventId_method:call(DemoHandler);
			if EventId ~= nil then
				DemoHandlerType = (cooking_events[EventId] == true and 1) or (eating_events[EventId] == true and 2) or (bbq_events[EventId] == true and 3) or nil;
			end
			if DemoHandlerType == nil then
				DemoHandler = nil;
			end
		end
	end
	return sdk_CALL_ORIGINAL;
end, function()
	if DemoHandler ~= nil and DemoHandlerType ~= nil then
		if (get_LoadState_method:call(DemoHandler) == LOADSTATE_ACTIVE) and (get_Playing_method:call(DemoHandler) == true) then
			reqFinish_method:call(DemoHandler, 0.0);
			if DemoHandlerType ~= 2 then
				DemoHandler = nil;
				if DemoHandlerType == 1 and not settings.skipEating then
					local kitchenFsm = sdk_get_managed_singleton("snow.gui.fsm.kitchen.GuiKitchenFsmManager");
					if kitchenFsm ~= nil then
						set_IsCookDemoSkip_method:call(kitchenFsm, true);
					end
				end
				DemoHandlerType = nil;
			end
		end
	end
end);

local function assertSafety(obj, objName)
    if obj:get_reference_count() <= 1 then
        log_info(objName .. " was disposed by the game, breaking");
        error("");
    end
end

re_on_frame(function()
	if not isRunning and DemoHandlerType == 2 then
		isRunning = true;
		pcall(function()
			assertSafety(DemoHandler, "DemoHandler");
			if get_LoadState_method:call(DemoHandler) >= LOADSTATE_UNLOADED then
				DemoHandler = nil;
				DemoHandlerType = nil;
				local guiManager = sdk_get_managed_singleton("snow.gui.GuiManager");
				local kitchenFsm = sdk_get_managed_singleton("snow.gui.fsm.kitchen.GuiKitchenFsmManager");
				if guiManager ~= nil and kitchenFsm ~= nil then
					assertSafety(guiManager, "guiManager");
					local GuiDangoLog = GuiDangoLog_field:get_data(guiManager);
					assertSafety(kitchenFsm, "kitchenFsm");
					local DangoLogParam = KitchenDangoLogParam_field:get_data(kitchenFsm);
					if GuiDangoLog ~= nil and DangoLogParam ~= nil then
						assertSafety(GuiDangoLog, "GuiDangoLog");
						assertSafety(DangoLogParam, "DangoLogParam");
						reqDangoLogStart_method:call(GuiDangoLog, DangoLogParam, 5.0);
					end
				end
			end
		end);
		isRunning = false;
	end
end);
---- re Callbacks ----
local function save_config()
	if jsonAvailable == true then
		json_dump_file("Skip_Dango_Song.json", settings);
	end
end

re_on_config_save(save_config);

re_on_draw_ui(function()
    if imgui_tree_node("Skip Dango Song") then
		local changed = false;
        changed, settings.skipDangoSong = imgui_checkbox("Skip the song", settings.skipDangoSong);
        changed, settings.skipEating = imgui_checkbox("Skip eating", settings.skipEating);
        changed, settings.skipMotley = imgui_checkbox("Skip Motley Mix", settings.skipMotley);
		if changed == true then
			if settings.skipDangoSong == false and settings.skipEating == false and settings.skipMotley == false then
				DemoHandler = nil;
				DemoHandlerType = nil;
				isRunning = nil;
			end
			save_config();
		end
        imgui_tree_pop();
    end
end);