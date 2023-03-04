local sdk = sdk;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_hook = sdk.hook;
local sdk_to_int64 = sdk.to_int64;
local sdk_to_managed_object = sdk.to_managed_object;
local sdk_SKIP_ORIGINAL = sdk.PreHookResult.SKIP_ORIGINAL;
local sdk_CALL_ORIGINAL = sdk.PreHookResult.CALL_ORIGINAL;

local log = log;
local log_info = log.info;

local require = require;

local misc_fixes = {};
local table_helpers;
local config;

local quest_manager_type_def = sdk_find_type_definition("snow.QuestManager");
local isPlayQuest_method = quest_manager_type_def:get_method("isPlayQuest");
local isEndWait_method = quest_manager_type_def:get_method("isEndWait");
local onChangedGameStatus_method = quest_manager_type_def:get_method("onChangedGameStatus");

local reqOnlineWarning_method = sdk_find_type_definition("snow.SnowSessionManager"):get_method("reqOnlineWarning");
local setOpenNetworkErrorWindowSelection_method = sdk_find_type_definition("snow.gui.GuiManager"):get_method("setOpenNetworkErrorWindowSelection");

local quest_status_index = 0;
local quest_manager = nil;

function misc_fixes.on_changed_game_status(new_quest_status)
	quest_status_index = new_quest_status;
end

function misc_fixes.on_req_online_warning()
	if not config.current_config.hide_online_warning.enabled then
		return sdk_CALL_ORIGINAL;
	end
	return sdk_SKIP_ORIGINAL;
end

function misc_fixes.on_set_open_network_error_window_selection(gui_manager)
	local cached_config = config.current_config.hide_network_errors;
	if not cached_config.enabled then
		return sdk_CALL_ORIGINAL;
	end

	if not quest_manager or quest_manager:get_reference_count() <= 1 then
		quest_manager = sdk_get_managed_singleton("snow.QuestManager");
		if not quest_manager then
			log_info("[Better Matchmaking] quest manager is missing");
			return sdk_CALL_ORIGINAL;
		end
	end

	local is_play_quest = isPlayQuest_method:call(quest_manager);
	local is_end_wait = isEndWait_method:call(quest_manager);

	if is_end_wait == nil or is_play_quest == nil then
		return sdk_CALL_ORIGINAL;
	end

	if quest_status_index == 2 then
		if is_play_quest then
			if cached_config.when_to_hide.on_quests then
				return sdk_SKIP_ORIGINAL;
			end
		else
			if is_end_wait then
				if cached_config.when_to_hide.on_quests then
					return sdk_SKIP_ORIGINAL;
				end
			else
				if cached_config.when_to_hide.outside_quests then
					return sdk_SKIP_ORIGINAL;
				end
			end
		end
	else
		if cached_config.when_to_hide.outside_quests then
			return sdk_SKIP_ORIGINAL;
		end
	end
end

function misc_fixes.init_module()
	config = require("Better_Matchmaking.config");
	table_helpers = require("Better_Matchmaking.table_helpers");

	sdk_hook(reqOnlineWarning_method, misc_fixes.on_req_online_warning);

	sdk_hook(onChangedGameStatus_method, function(args)
		misc_fixes.on_changed_game_status(sdk_to_int64(args[3]) & 0xFFFFFFFF);
	end);

	sdk_hook(setOpenNetworkErrorWindowSelection_method, function(args)
		return misc_fixes.on_set_open_network_error_window_selection(sdk_to_managed_object(args[2]));
	end);
end

return misc_fixes;
