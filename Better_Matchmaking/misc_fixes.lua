local this = {};

local utils;
local config;

local require = require;

local sdk = sdk;
local sdk_find_type_definition = sdk.find_type_definition;
local sdk_get_managed_singleton = sdk.get_managed_singleton;
local sdk_hook = sdk.hook;
local sdk_SKIP_ORIGINAL = sdk.PreHookResult.SKIP_ORIGINAL;

local get_CurrentStatus_method = sdk_find_type_definition("snow.SnowGameManager"):get_method("get_CurrentStatus"); -- retval
local StatusType_Quest = get_CurrentStatus_method:get_return_type():get_field("Quest"):get_data(nil);

local quest_manager_type_def = sdk_find_type_definition("snow.QuestManager");
local isPlayQuest_method = quest_manager_type_def:get_method("isPlayQuest"); -- retval
local isEndWait_method = quest_manager_type_def:get_method("isEndWait"); -- retval

local reqOnlineWarning_method = sdk_find_type_definition("snow.SnowSessionManager"):get_method("reqOnlineWarning");
local setOpenNetworkErrorWindowSelection_method = sdk_find_type_definition("snow.gui.GuiManager"):get_method("setOpenNetworkErrorWindowSelection(System.Guid, System.Boolean, System.String, System.Boolean)");

function this.on_req_online_warning()
	if config.current_config.hide_online_warning.enabled then
		return sdk_SKIP_ORIGINAL;
	end
end

function this.on_set_open_network_error_window_selection()
	if config.current_config.hide_network_errors.enabled then
		local GameManager = sdk_get_managed_singleton("snow.SnowGameManager");
		local quest_manager = sdk_get_managed_singleton("snow.QuestManager");
		if GameManager and quest_manager then
			if get_CurrentStatus_method:call(GameManager) == StatusType_Quest and (isPlayQuest_method:call(quest_manager) or isEndWait_method:call(quest_manager)) then
				if config.current_config.hide_network_errors.when_to_hide.on_quests then
					return sdk_SKIP_ORIGINAL;
				end
			else
				if config.current_config.hide_network_errors.when_to_hide.outside_quests then
					return sdk_SKIP_ORIGINAL;
				end
			end
		end
	end
end

function this.init_module()
	config = require("Better_Matchmaking.config");
	utils = require("Better_Matchmaking.utils");

	sdk_hook(reqOnlineWarning_method, this.on_req_online_warning);
	sdk_hook(setOpenNetworkErrorWindowSelection_method, this.on_set_open_network_error_window_selection);
end

return this;
